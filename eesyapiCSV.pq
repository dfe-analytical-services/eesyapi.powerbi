[Version = "1.0.0"]

section eesyapiCSV;

[DataSource.Kind="eesyapiCSV", Publish="eesyapiCSV.Publish"]
shared eesyapiCSV.Contents = () =>

let
    PublicationsJson =
        Json.Document(
            Web.Contents("https://api.education.gov.uk/statistics/v1/publications")
        ),

    PublicationsList = PublicationsJson[results],

    GroupedRecords =
        List.Transform(
            PublicationsList,
            each
                let
                    pubId = _[id],
                    pubTitle = _[title],

                    dsJson =
                        Json.Document(
                            Web.Contents(
                                "https://api.education.gov.uk/statistics/v1/publications/"
                                & pubId &
                                "/data-sets"
                            )
                        ),

                    dsList = dsJson[results],

                    DataSetItems =
                        List.Transform(
                            dsList,
                            (ds) =>
                                let
                                    dsTitle = ds[title],
                                    dsSummary = try ds[summary] otherwise "",

                                    displayName =
                                        if dsSummary <> "" then
                                            dsTitle & " - " & dsSummary
                                        else
                                            dsTitle
                                in
                                [
                                    Name = displayName,
                                    Key = ds[id],

                                    Data = LoadDataSetVersions(ds[id]),

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



LoadDataSetVersions = (dataSetId as text) =>

let
    VersionsJson =
        Json.Document(
            Web.Contents(
                "https://api.education.gov.uk/statistics/v1/data-sets/"
                & dataSetId &
                "/versions"
            )
        ),

    VersionsList = VersionsJson[results],

    SortedVersions =
        List.Sort(
            VersionsList,
            (x,y) => if x[version] > y[version] then -1 else 1
        ),

    LatestVersion = Text.From(SortedVersions{0}[version]),

    LatestItem =
        [
            Name = "Latest Version",
            Key = "latest",

            Data =
                LoadSelectedVersion(
                    dataSetId,
                    LatestVersion
                ),

            ItemKind = "Table",
            ItemName = "Table",
            IsLeaf = true
        ],

    OlderVersions =
        List.Transform(
            SortedVersions,
            each
                let
                    versionNumber = Text.From(_[version])
                in
                [
                    Name = "Version " & versionNumber,
                    Key = versionNumber,

                    Data =
                        LoadSelectedVersion(
                            dataSetId,
                            versionNumber
                        ),

                    ItemKind = "Table",
                    ItemName = "Table",
                    IsLeaf = true
                ]
        ),

    OlderVersionsTable =
        Table.ToNavigationTable(
            Table.FromRecords(OlderVersions),
            {"Key"},
            "Name",
            "Data",
            "ItemKind",
            "ItemName",
            "IsLeaf"
        ),

    FinalItems =
        {
            LatestItem,
            [
                Name = "Older Versions",
                Key = "older",
                Data = OlderVersionsTable,
                ItemKind = "Folder",
                ItemName = "Folder",
                IsLeaf = false
            ]
        },

    FinalTable =
        Table.ToNavigationTable(
            Table.FromRecords(FinalItems),
            {"Key"},
            "Name",
            "Data",
            "ItemKind",
            "ItemName",
            "IsLeaf"
        )

in
    FinalTable;



LoadSelectedVersion =
(dataSetId as text, version as text) =>

let
    DownloadUrl =
        "https://api.education.gov.uk/statistics/v1/data-sets/"
        & dataSetId &
        "/versions/"
        & version &
        "/csv",

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