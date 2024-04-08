# OSCAR MAQUEDA
# Get all subscriptions
subscriptions=$(az account list --query "[].id" -o tsv)

# Create a new JSON file for consumption details
echo "[" > consumptionDetails.json

# Create a new JSON file for recommendations
echo "[" > recommendations.json

# Loop through each subscription
for subscription in $subscriptions
do
    # Select the subscription
    az account set --subscription $subscription

    # Loop through the last three months
    for ((i=3; i>=1; i--))
    do
        # Get the first and last day of the month i months ago
        startDate=$(date -d "$(date +'%Y%m01') - $i month" +'%Y-%m-%d')
        endDate=$(date -d "$(date -d "$startDate + 1 month") - 1 day" +'%Y-%m-%d')

        # Get the consumption details
        consumptionDetails=$(az rest --method get --url "https://management.azure.com/subscriptions/$subscription/providers/Microsoft.Consumption/usageDetails?startDate=$startDate&endDate=$endDate&$top=1000&api-version=2019-10-01")

        # Calculate the total cost
        totalCost=$(echo $consumptionDetails | jq '[.value[].properties.paygCostInUSD, .value[].properties.CostInUSD] | map(select(. != null)) | add')

        # Output subscription ID, month, and total cost to the consumption details JSON file
        echo "{ \"subscriptionId\": \"$subscription\", \"month\": \"$startDate to $endDate\", \"totalCost\": $totalCost }," >> consumptionDetails.json
    done

    # Get the saving plans recommendations
    savingPlans=$(az rest --method get --url "https://management.azure.com/subscriptions/$subscription/providers/Microsoft.CostManagement/benefitRecommendations?api-version=2023-11-01")

    # Output subscription ID and saving plans to the recommendations JSON file
    echo "{ \"subscriptionId\": \"$subscription\", \"savingPlans\": $savingPlans }," >> recommendations.json
done

# Close the JSON arrays in the files
echo "]" >> consumptionDetails.json
echo "]" >> recommendations.json