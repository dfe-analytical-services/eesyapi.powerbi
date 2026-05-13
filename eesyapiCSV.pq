[Version = "1.0.0"]

section eesyapiCSV;

[DataSource.Kind="eesyapiCSV", Publish="eesyapiCSV.Publish"]
shared eesyapiCSV.Contents = () =>

let
    // =========================
    // 1. GET PUBLICATIONS
    // =========================
    PublicationsJson =
        Json.Document(
            Web.Contents("https://api.education.gov.uk/statistics/v1/publications")
        ),

    PublicationsList = PublicationsJson[results],

    // =========================
    // 2. BUILD PUBLICATION FOLDERS
    // =========================
    GroupedRecords =
        List.Transform(
            PublicationsList,
            each
                let
                    pubId = _[id],
                    pubTitle = _[title],

                    // =========================
                    // 3. GET DATASETS
                    // =========================
                    dsJson =
                        Json.Document(
                            Web.Contents(
                                "https://api.education.gov.uk/statistics/v1/publications/"
                                    & pubId
                                    & "/data-sets"
                            )
                        ),

                    dsList = dsJson[results],

                    // =========================
                    // 4. DATASET ITEMS
                    // =========================
                    DataSetItems =
                        List.Transform(
                            dsList,
                            (ds) =>
                                let
                                    dsTitle = ds[title],
                                    dsSummary = try ds[summary] otherwise "",
                                    dsId = ds[id],

                                    displayName =
                                        if dsSummary <> "" then
                                            dsTitle & " - " & dsSummary
                                        else
                                            dsTitle,

                                    // =========================
                                    // 5. GET DATASET VERSIONS
                                    // =========================
                                    versionsJson =
                                        Json.Document(
                                            Web.Contents(
                                                "https://api.education.gov.uk/statistics/v1/data-sets/"
                                                    & dsId
                                                    & "/versions"
                                            )
                                        ),

                                    versionsList = versionsJson[results],

                                    // =========================
                                    // 6. BUILD VERSION TABLE
                                    // =========================
                                    VersionItems =
                                        List.Transform(
                                            versionsList,
                                            (ver) =>
                                                let
                                                    verNum = Text.From(ver[version]),
                                                    releaseDate =
                                                        try Date.ToText(
                                                            Date.From(ver[published]),
                                                            "yyyy-MM-dd"
                                                        )
                                                        otherwise ""
                                                in
                                                    [
                                                        Name =
                                                            "Version "
                                                                & verNum
                                                                & " ("
                                                                & releaseDate
                                                                & ")",

                                                        Key = verNum,

                                                        Data =
                                                            LoadCSV(dsId),

                                                        ItemKind = "Table",
                                                        ItemName = "Table",
                                                        IsLeaf = true
                                                    ]
                                        ),

                                    VersionTable =
                                        Table.ToNavigationTable(
                                            Table.FromRecords(VersionItems),
                                            {"Key"},
                                            "Name",
                                            "Data",
                                            "ItemKind",
                                            "ItemName",
                                            "IsLeaf"
                                        )
                                in
                                    [
                                        Name = displayName,
                                        Key = dsId,
                                        Data = VersionTable,
                                        ItemKind = "Folder",
                                        ItemName = "Folder",
                                        IsLeaf = false
                                    ]
                        ),

                    NestedTable =
                        Table.ToNavigationTable(
                            Table.FromRecords(DataSetItems),
                            {"Key"},
                            "Name",
                            "Data",
                            "ItemKind",
                            "ItemName",
                            "IsLeaf"
                        )
                in
                    [
                        Name = pubTitle,
                        Key = pubId,
                        Data = NestedTable,
                        ItemKind = "Folder",
                        ItemName = "Folder",
                        IsLeaf = false
                    ]
        ),

    // =========================
    // 7. FINAL NAVIGATION
    // =========================
    NavTable = Table.FromRecords(GroupedRecords),

    FinalNav =
        Table.ToNavigationTable(
            NavTable,
            {"Key"},
            "Name",
            "Data",
            "ItemKind",
            "ItemName",
            "IsLeaf"
        )

in
    FinalNav;


// =========================
// 8. CSV LOADER
// =========================
LoadCSV = (dataSetId as text) =>
let
    DownloadUrl =
        "https://api.education.gov.uk/statistics/v1/data-sets/"
            & dataSetId
            & "/csv",

    Source =
        Csv.Document(
            Web.Contents(DownloadUrl),
            [
                Delimiter = ",",
                Encoding = 65001,
                QuoteStyle = QuoteStyle.Csv
            ]
        ),

    PromotedHeaders =
        Table.PromoteHeaders(Source, [PromoteAllScalars = true])

in
    PromotedHeaders;


// =========================
// 9. NAVIGATION HELPER
// =========================
Table.ToNavigationTable =
(
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>

let
    tableType = Value.Type(table),

    newTableType =
        Type.AddTableKey(tableType, keyColumns, true)
        meta
        [
            NavigationTable.NameColumn = nameColumn,
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn,
            NavigationTable.ItemNameColumn = itemNameColumn,
            NavigationTable.IsLeafColumn = isLeafColumn
        ],

    navigationTable =
        Value.ReplaceType(table, newTableType)

in
    navigationTable;


// =========================
// 10. CONNECTOR SETTINGS
// =========================
eesyapiCSV =
[
    Authentication = [
        Anonymous = []
    ],
    Label = "eesyapiCSV.Contents"
];

eesyapiCSV.Publish =
[
    Beta = true,
    Category = "Other",
    ButtonText = { "eesyapiCSV.Contents", "Connect" },
    SourceImage = eesyapiCSV.Icons,
    SourceTypeImage = eesyapiCSV.Icons
];

eesyapiCSV.Icons =
[
    Icon16 = {
        Extension.Contents("eesyapiCSV16.png"),
        Extension.Contents("eesyapiCSV20.png"),
        Extension.Contents("eesyapiCSV24.png"),
        Extension.Contents("eesyapiCSV32.png")
    },

    Icon32 = {
        Extension.Contents("eesyapiCSV32.png"),
        Extension.Contents("eesyapiCSV40.png"),
        Extension.Contents("eesyapiCSV48.png"),
        Extension.Contents("eesyapiCSV64.png")
    }
];