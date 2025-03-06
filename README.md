# eesyapi.powerbi
Custom connectors for connecting to the Explore Education Statistics service from PowerBI

# Using EES connectors

## Enabling custom connectors in Power BI

> 🚧 Warning
>
> If you've never used custom connectors in Power BI Desktop before, then you'll need to follow these steps before any of the instructions that follow below.

- Create the folder **Custom connectors/** in **Documents/Power BI Desktop/** (which itself may exist already, but depending on the system you're on and how it's set up, it may be within your OneDrive area or you might need to make your own).
- In Power BI Desktop go to **Settings > Global > Security > Data extensions** and **Allow any extension to load without validation or warning**.

## EES CSV endpoint connector

This connector retrieves an entire data set on request when given a data set ID. 

### Using this connector in Power BI

#### Step-by-step

- Complete the steps in [Enabling custom connectors in Power BI](#enabling-custom-connectors-in-power-bi) if this is your first time using a custom connector in Power BI Desktop.

- Copy the eesyapi CSV connector MEZ binary, **bin/AnyCPU/Debug/eesyapiCSV.mex**, from this repository to your PowerBI custom connectors folder, **Documents/Power BI Desktop/Custom connectors/**.

- From the Power BI Desktop home panel, select **Get data from other sources**.

- Enter **eesyapi** in the search box and then select **eesyapiCSV.Contents (Beta) (Custom)**.

- If prompted, click continue to accept this third party service.

- You should be prompted for a data set ID at this point, you can retrieve this from the data set's information page on Explore Education Statistics and paste it here. This should look something like: *e1ae9201-2fff-d376-8fa3-bd3c3660d4c8*.

- You should now see a preview of the data and have the choice to either **load** the data set or **transform** it.

> [!NOTE] 
> DfE data uses standard government symbols for missing data and these may be parsed as errors when connecting to the data via PowerBI. The data should still be returned fully, but with standard symbols such as *x*, *z* and *c* replaced by *Error*.

#### Live refreshes

As Microsoft have currently put [certification for custom connectors](https://learn.microsoft.com/en-us/fabric/data-factory/connector-certification) on hold, this software remains an uncertified connector. As an uncertified custom connector, it will require users to [set up an on-premises gateway](https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-onprem) to enable automatic refreshes of data in the Power BI Service. The gateway acts as a bridge between the Power BI Service in the cloud and the custom connector running locally on the user's machine, allowing datasets to automatically refresh by routing queries via the gateway to access the data source.

As soon as the certification process is live again, we plan to put this connector through the certification, enabling auto-refresh functionality without the need for further steps by end users.

# Contributing

These connectors are being developed in **VS Code** with the **Power Query SDK** extension installed.

If making changes to any power query script, make sure to run **Evaluate current file** on the corresponding *[script_name].query.pq* script in the **POWER QUERY SDK** panel under the file explorer pane in VS Code. This compiles the relevant *MEZ* binary file that can be used for debugging and that users can copy across to their custom connectors folder.

> 🚧 Warning
>
> If you run **Evaluate current file** on the base *[script_name].pq* script (as opposed to the *[script_name].query.pq* script), then Power Query SDK will likely double compile the script and give an error along the lines of `The export [script_name].Contents was exported multiple times.`

## Useful reference materials

The following are useful to read / watch if starting out on contributing.

- [Matt Masson's YouTube demo of creating a custom connector](https://www.youtube.com/watch?v=ecfRTEoYadI) (it's 7 years old, but *very* much worth a watch as a jumping off point if you're new to custom connectors).

- [DataConnectors GitHub repository with sample connectors](https://github.com/microsoft/DataConnectors/blob/master/README.md) (useful range of working examples of custom connectors).

## Acknowlegements

Thanks to Wayne Perry for giving us a steer towards custom connectors and a starting point in writing this one.
