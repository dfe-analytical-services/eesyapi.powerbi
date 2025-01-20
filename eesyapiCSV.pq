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
    // Query to fetch latest version details
    Source_Summary = Json.Document(Web.Contents("https://test.statistics.api.education.gov.uk/v1.0/data-sets/" & Dataset_Id)),
    Sessions_Table = Table.FromRecords({Source_Summary}),
    Expanded_latestVersion = Table.ExpandRecordColumn(Sessions_Table, "latestVersion", {"version", "published", "totalResults", "file", "timePeriods", "geographicLevels", "filters", "indicators"}, {"latestVersion.version", "latestVersion.published", "latestVersion.totalResults", "latestVersion.file", "latestVersion.timePeriods", "latestVersion.geographicLevels", "latestVersion.filters", "latestVersion.indicators"}),
    Expanded_latestVersion.file = Table.ExpandRecordColumn(Expanded_latestVersion, "latestVersion.file", {"id"}, {"latestVersion.file.id"}),
    Expanded_latestVersion.timePeriods = Table.ExpandRecordColumn(Expanded_latestVersion.file, "latestVersion.timePeriods", {"start", "end"}, {"latestVersion.timePeriods.start", "latestVersion.timePeriods.end"}),
    Changed_Type = Table.TransformColumnTypes(Expanded_latestVersion.timePeriods,{{"latestVersion.published", type text}}),

    // Extracting the latest version details
    Latest_Version_Number = Changed_Type{0}[latestVersion.version],

    // Main query using the latest version details
    Source_Csv = Csv.Document(Web.Contents("https://test.statistics.api.education.gov.uk/v1.0/data-sets/" & Dataset_Id & "/csv?dataSetVersion=" & Latest_Version_Number), [Delimiter=",", Encoding=1252, QuoteStyle=QuoteStyle.None]),
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

