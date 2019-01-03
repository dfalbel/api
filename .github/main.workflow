workflow "Deploy" {
  on = "push"
  resolves = [
    "Build docker image",
    "Auth Google",
    "Tag image for GCR",
    "Push image to GCR",
    "Set Credential Helper for Docker",
    "Load GKE kube credentials",
    "Deploy to GKE",
    "Expose service"
  ]
}

action "Build docker image" {
  uses = "actions/docker/cli@master"
  args = ["build", "-t", "api", "."]
}

action "Auth Google" {
  uses = "actions/gcloud/auth@master"
  secrets = ["GCLOUD_AUTH"]
}

action "Set Credential Helper for Docker" {
  needs = ["Build docker image", "Auth Google"]
  uses = "actions/gcloud/cli@master"
  args = ["auth", "configure-docker", "--quiet"]
}

action "Tag image for GCR" {
  needs = ["Auth Google", "Build docker image"]
  uses = "actions/docker/tag@master"
  env = {
    PROJECT_ID = "decryptr-196601"
    APPLICATION_NAME = "api"
  }
  args = ["api", "gcr.io/$PROJECT_ID/$APPLICATION_NAME"]
}

action "Push image to GCR" {
  needs = ["Tag image for GCR", "Set Credential Helper for Docker"]
  uses = "actions/gcloud/cli@master"
  runs = "sh -c"
  env = {
    PROJECT_ID = "decryptr-196601"
    APPLICATION_NAME = "api"
  }
  args = ["docker push gcr.io/$PROJECT_ID/$APPLICATION_NAME"]
}

action "Load GKE kube credentials" {
  needs = ["Push image to GCR", "Auth Google"]
  uses = "actions/gcloud/cli@master"
  env = {
    PROJECT_ID = "decryptr-196601"
    CLUSTER_NAME = "api"
  }
  args = "container clusters get-credentials $CLUSTER_NAME --zone us-central1-a --project $PROJECT_ID"
}

action "Deploy to GKE" {
  needs = ["Push image to GCR", "Load GKE kube credentials"]
  uses = "docker://gcr.io/cloud-builders/kubectl"
  env = {
    PROJECT_ID = "decryptr-196601"
    APPLICATION_NAME = "api"
    DEPLOYMENT_NAME = "decryptr-api"
  }
  runs = "sh -l -c"
  args = ["kubectl run --image=gcr.io/$PROJECT_ID/$APPLICATION_NAME $DEPLOYMENT_NAME --port=8080 --image-pull-policy Always"]
}

action "Expose service" {
  needs = ["Deploy to GKE"]
  uses = "docker://gcr.io/cloud-builders/kubectl"
  env = {
    DEPLOYMENT_NAME = "decryptr-api"
  }
  runs = "sh -l -c"
  args = ["kubectl expose deployment $DEPLOYMENT_NAME --type LoadBalancer --port 80 --target-port 8080"]
}
