// This file contains Data Connector logic
[Version = "1.0.0"]
section eesyapiConnector;


[DataSource.Kind="eesyapiConnector", Publish="eesyapiConnector.Publish"]
shared eesyapiConnector.Contents = () =>
    let
    // Query to fetch latest version details
    Dataset_Id = Text.From("e1ae9201-2fff-d376-8fa3-bd3c3660d4c8"),
    Source_Summary = Json.Document(Web.Contents("https://test.statistics.api.education.gov.uk/v1.0/data-sets/" & Dataset_Id)),
    Sessions_Table = Table.FromRecords({Source_Summary}),
    Expanded_latestVersion = Table.ExpandRecordColumn(Sessions_Table, "latestVersion", {"version", "published", "totalResults", "file", "timePeriods", "geographicLevels", "filters", "indicators"}, {"latestVersion.version", "latestVersion.published", "latestVersion.totalResults", "latestVersion.file", "latestVersion.timePeriods", "latestVersion.geographicLevels", "latestVersion.filters", "latestVersion.indicators"}),
    Expanded_latestVersion.file = Table.ExpandRecordColumn(Expanded_latestVersion, "latestVersion.file", {"id"}, {"latestVersion.file.id"}),
    Expanded_latestVersion.timePeriods = Table.ExpandRecordColumn(Expanded_latestVersion.file, "latestVersion.timePeriods", {"start", "end"}, {"latestVersion.timePeriods.start", "latestVersion.timePeriods.end"}),
    Changed_Type = Table.TransformColumnTypes(Expanded_latestVersion.timePeriods,{{"latestVersion.published", type text}}),

    // Extracting the latest version details
    Latest_Version_Number = Changed_Type{0}[latestVersion.version],

    // Main query using the latest version details
    Source_Csv = Csv.Document(Web.Contents("https://test.statistics.api.education.gov.uk/v1.0/data-sets/" & Dataset_Id & "/csv?dataSetVersion=" & Latest_Version_Number), [Delimiter=",", Columns=22, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    Data_With_Headers = Table.PromoteHeaders(Source_Csv, [PromoteAllScalars=true]),
    Data_Set = Table.TransformColumnTypes(Data_With_Headers, {{"time_period", type text}, {"time_identifier", type text}, {"geographic_level", type text}, {"country_code", type text}, {"country_name", type text}})

in
    Data_Set;

// Data Source Kind description
eesyapiConnector = [
    Authentication = [
        UsernamePassword = [] // Power BI will prompt user for credentials
    ]
];

// Data Source UI publishing description
eesyapiConnector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = eesyapiConnector.Icons,
    SourceTypeImage = eesyapiConnector.Icons
];

eesyapiConnector.Icons = [
    Icon16 = { Extension.Contents("eesyapiConnector16.png"), Extension.Contents("eesyapiConnector20.png"), Extension.Contents("eesyapiConnector24.png"), Extension.Contents("eesyapiConnector32.png") },
    Icon32 = { Extension.Contents("eesyapiConnector32.png"), Extension.Contents("eesyapiConnector40.png"), Extension.Contents("eesyapiConnector48.png"), Extension.Contents("eesyapiConnector64.png") }
];

