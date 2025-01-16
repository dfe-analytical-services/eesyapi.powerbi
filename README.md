# eesyapi.powerbi
Custom connectors for connecting to the Explore Education Statistics service from PowerBI

# Using EES connectors

## Enabling custom connectors in Power BI

> 🚧 Warning
>
> If you've never used custom connectors in Power BI Desktop before, then you'll need to follow these steps before any of the instructions that follow below.

- Create the folder **Custom connectors/** in **Documents/Power BI Desktop/** (which itself should exist already, but depending on the system you're on and how it's set up, may be within your OneDrive area).
- In Power BI Desktop go to **Settings > Global > Security > Data extensions** and **Allow any extension to load without validation or warning**.

## Demo EES CSV endpoint connector

We provide a demo connector to one of the EES API data sets, which downloads the entire data set (16 rows). 

### Using this connector in Power BI

- Complete the steps in [Enabling custom connectors in Power BI](#enabling-custom-connectors-in-power-bi) if this is your first time using a custom connector in Power BI Desktop.

- Copy the demo connector power query, **eesyapiDemoConnector.pq**, from this repository to your PowerBI custom connectors folder, **Documents/Power BI Desktop/Custom connectors/**.

- From the Power BI Desktop home panel, select **Get data from other sources**.

- Enter **eesyapi** in the search box and then select **eesyapiDemoConnector.Contents (Beta) (Custom)**.

- Click continue to accept this third part service.

- You should now see a preview of the data and have the choice to either **load** the data set or **transform** it.

# Contributing

These connectors are being developed in **VS Code** with the **Power Query SDK** extension installed.

If making changes to any power query script, it's worth running **Evaluate current file** on the corresponding *[script_name].query.pq* script in the **POWER QUERY SDK** panel under the file explorer pane in VS Code. This compiles the relevant *MEZ* binary files for running and debugging.

> 🚧 Warning
>
> If you run **Evaluate current file** on the base *[script_name].pq* script (as opposed to the *[script_name].query.pq* script), then Power Query SDK will likely double compile the script and give an error along the lines of `The export [script_name].Contents was exported multiple times.`

## Useful reference materials

The following are useful to read / look through if starting out on contributing.

- [DataConnectors GitHub repository with sample connectors](https://github.com/microsoft/DataConnectors/blob/master/README.md)
