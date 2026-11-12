// ============================================================
// QUERY 1: clean the messy client export (raw_client_export_Q4_2025.csv)
// In the UI each line below is one click; the Applied Steps pane records them.
// Advanced editor: replace the file path / connector with your own.
// ============================================================
let
    Source      = Csv.Document(File.Contents("raw_client_export_Q4_2025.csv"),
                    [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),

    // 1. Remove the junk lines the POS system writes above the header
    //    (UI: Home > Remove rows > Remove top rows; this version skips until it sees the header)
    SkipJunk    = Table.Skip(Source, each [Column1] <> "Order #"),

    // 2. Use first row as headers
    Promoted    = Table.PromoteHeaders(SkipJunk, [PromoteAllScalars = true]),

    // 3. Remove blank rows and the empty Notes column
    NoBlanks    = Table.SelectRows(Promoted, each [#"Order #"] <> null and [#"Order #"] <> ""),
    NoNotes     = Table.RemoveColumns(NoBlanks, {"Notes"}),

    // 4. Remove duplicate rows (25 in this file)
    Deduped     = Table.Distinct(NoNotes),

    // 5. Split "Denver, CO" into City + State
    SplitLoc    = Table.SplitColumn(Deduped, "Store Location",
                    Splitter.SplitTextByDelimiter(", ", QuoteStyle.Csv), {"City", "State"}),

    // 6. Standardise Region (Mtn, MOUNTAIN, "mountain " -> Mountain ...)
    RegionUp    = Table.TransformColumns(SplitLoc, {{"Region", each Text.Upper(Text.Trim(_)), type text}}),
    RegionClean = Table.AddColumn(RegionUp, "Region Clean", each
                    if List.Contains({"MOUNTAIN", "MTN"}, [Region]) then "Mountain"
                    else if List.Contains({"SOUTHWEST", "SW", "SOUTH WEST"}, [Region]) then "Southwest"
                    else if List.Contains({"PACIFIC", "PAC"}, [Region]) then "Pacific"
                    else if List.Contains({"MIDWEST", "MID-WEST"}, [Region]) then "Midwest"
                    else if [Region] = "SOUTH" then "South"
                    else "Unknown", type text),
    SwapRegion  = Table.RenameColumns(Table.RemoveColumns(RegionClean, {"Region"}), {{"Region Clean", "Region"}}),

    // 7. Parse dates that arrive in 3 different formats
    Dates       = Table.TransformColumns(SwapRegion, {{"Order Date", each
                    try Date.FromText(_, [Format = "MM/dd/yyyy", Culture = "en-US"])
                    otherwise try Date.FromText(_, [Format = "yyyy-MM-dd", Culture = "en-US"])
                    otherwise Date.FromText(_, [Format = "dd-MMM-yyyy", Culture = "en-US"]), type date}}),

    // 8. "$1,234.56" text -> 1234.56 number; blank Qty -> null
    Money       = Table.TransformColumns(Dates, {{"Sales Amount", each
                    Number.FromText(Text.Remove(_, {"$", ","}), "en-US"), type number}}),
    Qty         = Table.TransformColumns(Money, {{"Qty", each
                    if _ = "" then null else Number.FromText(_, "en-US"), Int64.Type}}),

    // 9. Fix product name casing (TRAILHEAD 2P TENT -> Trailhead 2P Tent)
    //    by merging with the clean Products query (like dplyr::left_join)
    ProdKey     = Table.AddColumn(Qty, "ProductKey", each Text.Upper(Text.Trim([Product])), type text),
    ProductsKey = Table.AddColumn(Products, "ProductKey", each Text.Upper([ProductName]), type text),
    Merged      = Table.NestedJoin(ProdKey, {"ProductKey"}, ProductsKey, {"ProductKey"}, "P", JoinKind.LeftOuter),
    Expanded    = Table.ExpandTableColumn(Merged, "P", {"ProductID", "ProductName"}),
    Final       = Table.RemoveColumns(Expanded, {"Product", "ProductKey"})
in
    Final


// ============================================================
// QUERY 2: combine every CSV the client drops into a SharePoint/OneDrive folder
// New file appears -> next scheduled refresh picks it up. No code change.
// (Get data > SharePoint folder > Combine. This is what the UI generates, simplified.)
// ============================================================
// let
//     Source   = SharePoint.Files("https://YOURTENANT.sharepoint.com/sites/YOURSITE", [ApiVersion = 15]),
//     Drops    = Table.SelectRows(Source, each Text.Contains([Folder Path], "/client_drops/")
//                                          and Text.EndsWith([Name], ".csv")),
//     Parsed   = Table.AddColumn(Drops, "Data", each
//                  Table.PromoteHeaders(Csv.Document([Content], [Delimiter = ",", Encoding = 65001]),
//                                       [PromoteAllScalars = true])),
//     Keep     = Table.SelectColumns(Parsed, {"Name", "Data"}),
//     Expanded = Table.ExpandTableColumn(Keep, "Data",
//                  {"OrderID", "OrderDate", "StoreID", "ProductID", "Channel",
//                   "Quantity", "UnitPrice", "Discount", "Revenue", "Cost"}),
//     Typed    = Table.TransformColumnTypes(Expanded, {
//                  {"OrderDate", type date}, {"Quantity", Int64.Type}, {"UnitPrice", type number},
//                  {"Discount", type number}, {"Revenue", type number}, {"Cost", type number}})
// in
//     Typed
