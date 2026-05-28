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
                                    // 5. GET ALL DATASET VERSIONS
                                    // =========================
                                    FetchAllVersions = (pageNumber as number) as list =>
                                        let
                                            CurrentUrl =
                                                "https://api.education.gov.uk/statistics/v1/data-sets/"
                                                    & dsId
                                                    & "/versions?page="
                                                    & Text.From(pageNumber),

                                            Response =
                                                Json.Document(
                                                    Web.Contents(CurrentUrl)
                                                ),

                                            CurrentResults = Response[results],

                                            NextPageExists =
                                                try (
                                                    Response[paging][page]
                                                        < Response[paging][totalPages]
                                                )
                                                otherwise false,

                                            NextResults =
                                                if NextPageExists then
                                                    @FetchAllVersions(pageNumber + 1)
                                                else
                                                    {}
                                        in
                                            List.Combine(
                                                {
                                                    CurrentResults,
                                                    NextResults
                                                }
                                            ),

                                    versionsList = FetchAllVersions(1),

                                    // =========================
                                    // 6. BUILD VERSION RECORDS
                                    // =========================
                                    VersionItems =
                                        List.Transform(
                                            versionsList,
                                            (ver) =>
                                                let
                                                    verNum =
                                                        Text.From(ver[version]),

                                                    versionParts =
                                                        Text.Split(verNum, "."),

                                                    majorPart =
                                                        try Number.From(versionParts{0})
                                                        otherwise 0,

                                                    minorPart =
                                                        try Number.From(versionParts{1})
                                                        otherwise 0,

                                                    patchPart =
                                                        try Number.From(versionParts{2})
                                                        otherwise 0,

                                                    rawDateStr =
                                                        try ver[published]
                                                        otherwise (
                                                            try ver[publishedDate]
                                                            otherwise (
                                                                try ver[updated]
                                                                otherwise (
                                                                    try ver[lastUpdated]
                                                                    otherwise ""
                                                                )
                                                            )
                                                        ),

                                                    cleanDateStr =
                                                        if Text.Length(rawDateStr) >= 10 then
                                                            Text.Start(rawDateStr, 10)
                                                        else
                                                            rawDateStr,

                                                    parsedDate =
                                                        try Date.From(cleanDateStr)
                                                        otherwise #date(1970, 1, 1),

                                                    releaseDateText =
                                                        if parsedDate = #date(1970, 1, 1) then
                                                            "Date Pending"
                                                        else
                                                            Date.ToText(
                                                                parsedDate,
                                                                "dd-MM-yyyy"
                                                            )
                                                in
                                                    [
                                                        BaseVerNum = verNum,
                                                        ReleaseDate = releaseDateText,
                                                        SortDate = parsedDate,
                                                        Major = majorPart,
                                                        Minor = minorPart,
                                                        Patch = patchPart
                                                    ]
                                        ),

                                    VersionTableRaw =
                                        Table.FromRecords(VersionItems),

                                    // =========================
                                    // SORT LATEST FIRST (CRITICAL SORT)
                                    // =========================
                                    SortedVersionTableLocal =
                                        Table.Sort(
                                            VersionTableRaw,
                                            {
                                                {"SortDate", Order.Descending},
                                                {"Major", Order.Descending},
                                                {"Minor", Order.Descending},
                                                {"Patch", Order.Descending}
                                            }
                                        ),

                                    // =========================
                                    // INTERNAL SORT INDEX
                                    // =========================
                                    WithRankIndex =
                                        Table.AddIndexColumn(
                                            SortedVersionTableLocal,
                                            "RankIndex",
                                            1,
                                            1,
                                            Int64.Type
                                        ),

                                    // =========================
                                    // FINAL VERSION STRUCTURE
                                    // =========================
                                    FinalVersionRecords =
                                        Table.AddColumn(
                                            WithRankIndex,
                                            "FinalStructure",
                                            each
                                                let
                                                    // FIX: RankIndex ko text banaya padding ke sath (01, 02, etc.) taaki Power BI automatic standard sorting follow kare
                                                    PrefixNumber = Text.PadStart(Text.From(_[RankIndex]), 2, "0"),
                                                    
                                                    // Yeh aapko Top Most sort bhi dega aur Data panel me poora text bhi dikhayega
                                                    SortedDisplayName =
                                                        PrefixNumber 
                                                            & ". Version "
                                                            & _[BaseVerNum]
                                                            & " ("
                                                            & _[ReleaseDate]
                                                            & ")"
                                                in
                                                    [
                                                        Name = SortedDisplayName,

                                                        Key = _[BaseVerNum],

                                                        Data =
                                                            Expression.Evaluate(
                                                                "() => LoadCSV(""" & dsId & """, """ & _[BaseVerNum] & """, """ & _[ReleaseDate] & """)",
                                                                [LoadCSV = LoadCSV]
                                                            )(),

                                                        ItemKind = "Table",
                                                        
                                                        // Name ko hi ItemName banaya taaki Data Panel me wahi ordered naam saaf dikhe
                                                        ItemName = SortedDisplayName,
                                                        IsLeaf = true
                                                    ]
                                        ),

                                    CleanVersionTable =
                                        Table.FromRecords(
                                            FinalVersionRecords[FinalStructure]
                                        ),

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
LoadCSV = (dataSetId as text, versionNum as text, releaseDate as text) =>
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
        Table.PromoteHeaders(Source, [PromoteAllScalars = true]),

    AddVersionColumn = Table.AddColumn(PromotedHeaders, "Dataset Version", each versionNum, type text),
    AddDateColumn = Table.AddColumn(AddVersionColumn, "Release Date", each releaseDate, type text)

in
    AddDateColumn;


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
        Extension.Contents("eesyapiCSV16.png")
    },

    Icon32 = {
        Extension.Contents("eesyapiCSV32.png")
    }
];