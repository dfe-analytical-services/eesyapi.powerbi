[Version = "1.0.0"]

section eesyapiCSV;

[DataSource.Kind="eesyapiCSV", Publish="eesyapiCSV.Publish"]
shared eesyapiCSV.Contents = () =>

let
    // =========================
    // 1. PUBLICATIONS FETCH
    // =========================
    PublicationsJson =
        Json.Document(
            Web.Contents("https://api.education.gov.uk/statistics/v1/publications")
        ),

    PublicationsList = PublicationsJson[results],

    // =========================
    // 2. BUILD FOLDERS (PUBLICATIONS)
    // =========================
    GroupedRecords =
        List.Transform(
            PublicationsList,
            each
                let
                    pubId = _[id],
                    pubTitle = _[title],

                    // =========================
                    // 3. DATASETS FETCH
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
                    // 4. DATASET ITEMS (TABLE LEVEL)
                    // =========================
                    DataSetItems =
                        List.Transform(
                            dsList,
                            (ds) =>
                                let
                                    dsTitle = ds[title],
                                    dsSummary = try ds[summary] otherwise "",

                                    // 👉 CLEAN DISPLAY NAME (TITLE + SUMMARY)
                                    displayName =
                                        if dsSummary <> "" then
                                            dsTitle & " - " & dsSummary
                                        else
                                            dsTitle
                                in
                                [
                                    Name = displayName,
                                    Key = ds[id],

                                    Data =
                                        LoadSelectedData(ds[id]),

                                    ItemKind = "Table",
                                    ItemName = "Table",
                                    IsLeaf = true
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
    // 5. FINAL NAVIGATION TABLE
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
// 6. DATA LOADER (CSV)
// =========================
LoadSelectedData = (dataSetId as text) =>
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
// 7. NAVIGATION HELPER
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
            NavigationTable.IsLeafColumn = isLeafColumn,
            Preview.DelayColumn = "Description"
        ],

    navigationTable =
        Value.ReplaceType(table, newTableType)

in
    navigationTable;


// =========================
// 8. CONNECTOR SETTINGS
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