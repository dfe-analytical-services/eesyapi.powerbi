// This file contains Data Connector logic
section eesyapiCSV;


[DataSource.Kind="eesyapiCSV", Publish="eesyapiCSV.Publish"]
shared eesyapiCSV.Contents = Value.ReplaceType(ContentsImpl, eesyapiContentsType);

eesyapiContentsType = type function(
    Dataset_Id as (type text meta [
        Documentation.FieldCaption = "Data set ID",
        Documentation.FieldDescription = "ID of the data set on Explore Education Statistics",
        DataSource.Path = false // don't include in data source path calculation
    ])
    )

    as table meta [
        Documentation.Name = "EES data set",
        Documentation.LongDescription = "Retrieve an EES data set from its CSV endpoint"
    ];

ContentsImpl = (Dataset_Id as text) =>
    let
    // Query the latest version
    Source_Csv = Csv.Document(Web.Contents("https://api.education.gov.uk/statistics/v1/data-sets/" & Dataset_Id & "/csv?dataSetVersion=*"), [Delimiter=",", Encoding=1252, QuoteStyle=QuoteStyle.None]),
    Data_With_Headers = Table.PromoteHeaders(Source_Csv, [PromoteAllScalars=true]),
    Data_Set = Table.TransformColumnTypes(Data_With_Headers, {{"time_period", type text}, {"time_identifier", type text}, {"geographic_level", type text}, {"country_code", type text}, {"country_name", type text}})

in
    Data_Set;

// Data Source Kind description
eesyapiCSV = [
    Authentication = [
        Anonymous = []
    ]
];

// Data Source UI publishing description
eesyapiCSV.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://dfe-analytical-services.github.io/explore-education-statistics-api-docs/",
    SourceImage = eesyapiCSV.Icons,
    SourceTypeImage = eesyapiCSV.Icons
];

eesyapiCSV.Icons = [
    Icon16 = { 
        Extension.Contents("eesyapi16.png"),
        Extension.Contents("eesyapi32.png")
        },
    Icon32 = {
        Extension.Contents("eesyapi32.png"),
        Extension.Contents("eesyapi64.png"),
        Extension.Contents("eesyapi120.png")
        }
];

