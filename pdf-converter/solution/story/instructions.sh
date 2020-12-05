# Convert a Node JS application to a container.
# Build containers with Google Cloud Build.
# Create a Cloud Run service that converts files to PDF files in the cloud.
# Use event processing with Google Cloud Storage


# Configure Gcloud with project
gcloud config set project reju-cloud-devjam 
GOOGLE_CLOUD_PROJECT=reju-cloud-devjam
PROJECT_NUMBER=171082686956

# Configure & Access the generated Cloud Run Service URL
SERVICE_URL=https://pdf-converter-5sqlswdrba-uc.a.run.app
curl -X POST $SERVICE_URL
curl -X POST -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL

# Create Buckets for Input Documents Uploads and Comverted PDF files

gsutil mb gs://$GOOGLE_CLOUD_PROJECT-upload
gsutil mb gs://$GOOGLE_CLOUD_PROJECT-processed

# Create a Topic in Pub/Sub for handling uploaded input files in the bucket
gsutil notification create -t new-doc -f json -e OBJECT_FINALIZE gs://$GOOGLE_CLOUD_PROJECT-upload

# Create service account and configure IAM policies
gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"
gcloud beta run services add-iam-policy-binding pdf-converter --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --platform managed --region us-central1
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator

# Create a handler (subscription) for the Pub/Sub
gcloud beta pubsub subscriptions create pdf-conv-sub --topic new-doc --push-endpoint=$SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com

# Final test by uploading the input files
gsutil -m cp gs://spls/gsp644/* gs://$GOOGLE_CLOUD_PROJECT-upload

# Review the output
gsutil -m cp gs://spls/gsp644/* gs://$GOOGLE_CLOUD_PROJECT-processed
