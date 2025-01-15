# eesyapi.powerbi
Custom connectors for connecting to the Explore Education Statistics service from PowerBI

# Contributing

These connectors are being developed in VS Code with the Power Query SDK extension installed.

If making changes to any power query script, it's worth running **POWER QUERY SDK > Evaluate current file** under the file explorer pain in VS Code. This compiles the relevant *MEZ* binary files for debugging.

*Note: I've not figured out how to get the authentication working in VS Code yet, so the debugging doesn't actually work right now.*

# Using EES connectors

## Demo EES CSV endpoint connector

We provide a demo connector to one of the EES API data sets, which downloads the entire data set (16 rows). 

To use this connector in Power BI:

1. Copy the demo connector power query, **eesyapiDemoConnector.pq**, from this repository to your PowerBI custom connectors folder, **Documents/Power BI Desktop/Custom connectors/**.

2. Open Power BI Desktop and select **Get data from other sources**.

3. Enter **eesyapi* in the search box and then select **eesyapiDemoConnector.Contents (Beta) (Custom)**.

4. Click continue to accept this third part service.

5. You should now see a preview of the data and have the choice to either **load** the data set or **transform* it.

