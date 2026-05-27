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
                                    // 5. GET ALL DATASET VERSIONS (PAGINATED LOOP)
                                    // =========================
                                    FetchAllVersions = (pageNumber as number) as list =>
                                        let
                                            CurrentUrl = "https://api.education.gov.uk/statistics/v1/data-sets/" 
                                                         & dsId 
                                                         & "/versions?page=" 
                                                         & Text.From(pageNumber),
                                            Response = Json.Document(Web.Contents(CurrentUrl)),
                                            CurrentResults = Response[results],
                                            
                                            NextPageExists = try (Response[paging][page] < Response[paging][totalPages]) otherwise false,
                                            NextResults = if NextPageExists then @FetchAllVersions(pageNumber + 1) else {}
                                        in
                                            List.Combine({CurrentResults, NextResults}),

                                    versionsList = FetchAllVersions(1),

                                    // =========================
                                    // 6. BUILD VERSION RECORDS WITH NUMERIC PARTS
                                    // =========================
                                    VersionItems =
                                        List.Transform(
                                            versionsList,
                                            (ver) =>
                                                let
                                                    verNum = Text.From(ver[version]),
                                                    
                                                    // Numeric Split logic for perfect version sorting (e.g., "2.12" -> Major=2, Minor=12)
                                                    versionParts = Text.Split(verNum, "."),
                                                    majorPart = try Number.From(versionParts{0}) otherwise 0,
                                                    minorPart = try Number.From(versionParts{1}) otherwise 0,
                                                    
                                                    rawDateStr = try ver[published] otherwise 
                                                                 (try ver[publishedDate] otherwise 
                                                                 (try ver[updated] otherwise 
                                                                 (try ver[lastUpdated] otherwise ""))),
                                                    
                                                    cleanDateStr = if Text.Length(rawDateStr) >= 10 then Text.Start(rawDateStr, 10) else rawDateStr,
                                                    
                                                    parsedDate = try Date.From(cleanDateStr) otherwise #date(1970, 1, 1),
                                                    
                                                    releaseDateText = if parsedDate = #date(1970, 1, 1) then "Date Pending" else Date.ToText(parsedDate, "dd-MM-yyyy"),
                                                    
                                                    finalName = "Version " & verNum & " (" & releaseDateText & ")"
                                                in
                                                    [
                                                        Name = finalName,
                                                        Key = verNum,
                                                        Data = Expression.Evaluate("() => LoadCSV(""" & dsId & """)", [LoadCSV = LoadCSV])(),
                                                        ItemKind = "Table",
                                                        ItemName = "Table",
                                                        IsLeaf = true,
                                                        SortDate = parsedDate,
                                                        Major = majorPart,
                                                        Minor = minorPart
                                                    ]
                                        ),

                                    VersionTableRaw = Table.FromRecords(VersionItems),

                                    // =========================
                                    // CRITICAL FIX: MULTI-LAYERED TRUE DESCENDING SORT
                                    // =========================
                                    // 1st Priority: Newest Date 
                                                    // 2nd Priority: Highest Major Version Number (e.g., 2.x over 1.x)
                                                    // 3rd Priority: Highest Minor Version Number (e.g., 2.12 over 2.2)
                                    SortedVersionTable = Table.Sort(
                                        VersionTableRaw, 
                                        {
                                            {"SortDate", Order.Descending}, 
                                            {"Major", Order.Descending}, 
                                            {"Minor", Order.Descending}
                                        }
                                    ),
                                    
                                    // Cleanup tracking sorting columns before loading UI
                                    CleanVersionTable = Table.RemoveColumns(SortedVersionTable, {"SortDate", "Major", "Minor"}),

                                    VersionTable =
                                        Table.ToNavigationTable(
                                            CleanVersionTable,
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