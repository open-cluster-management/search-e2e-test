git clone git@github.ibm.com:IBMPrivateCloud/search-chart
cd search-chart

kubectl delete secret my-docker-secret -n kube-system
kubectl create secret docker-registry -n kube-system  my-docker-secret --docker-server=${DOCKER_SERVER}  --docker-username=${DOCKER_USERNAME} --docker-password=${DOCKER_PASSWORD}

# make local for search-chart
echo "Building the search chart"
for file in `find . -name values.yaml`; do echo $file; sed -i -e "s|ibmcom|hyc-cloud-private-integration-docker-local.artifactory.swg-devops.com/ibmcom|g" $file; done
make build

echo "Installing search chart"

helm upgrade --install search --namespace kube-system --set global.pullSecret=my-docker-secret --set global.tillerIntegration.user=admin repo/stable/ibm-search-prod-99.99.99.tgz --tls --recreate-pods

cd ..

kubectl get pods -n kube-system | grep search


## declare an array variable
declare -a arr=(
"search-search-api"
"search-search-aggregator"
"search-search-collector"
"search-redisgraph"
)
success=true

## now loop through the above array
IFS=""
for i in "${arr[@]}"
do
results=$(kubectl rollout status --timeout=300s -n kube-system deployment "$i")
echo "$results"
if [[ "$results" != *"successfully rolled out"* ]]; then
success=false
fi
done

# ...do something interesting...
if [ "$success" = true ] ; then
echo 'Proceeding with installation'
else
echo 'Cannot proceed with installation. Please check search deployments'
fi
