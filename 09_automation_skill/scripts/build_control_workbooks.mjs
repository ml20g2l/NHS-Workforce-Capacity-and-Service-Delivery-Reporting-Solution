import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

function arg(name) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

const qualityPath = arg("--quality-json");
const reconciliationPath = arg("--reconciliation-json");
const outputDir = arg("--output-dir");
if (!qualityPath || !reconciliationPath || !outputDir) {
  throw new Error("Usage: node build_control_workbooks.mjs --quality-json <file> --reconciliation-json <file> --output-dir <folder>");
}

const qualityRows = JSON.parse(await fs.readFile(qualityPath, "utf8"));
const reconciliationRows = JSON.parse(await fs.readFile(reconciliationPath, "utf8"));
const destination = path.resolve(outputDir);
await fs.mkdir(destination, { recursive: true });

function addTableWorkbook(sheetName, title, rows) {
  const workbook = Workbook.create();
  const sheet = workbook.worksheets.add(sheetName);
  const headers = [...new Set(rows.flatMap((row) => Object.keys(row)))];
  const body = rows.length ? rows.map((row) => headers.map((header) => row[header] ?? "")) : [headers.map(() => "No rows")];
  const lastColumn = String.fromCharCode(64 + Math.max(headers.length, 1));
  const endRow = body.length + 2;
  sheet.getRange(`A1:${lastColumn}1`).merge();
  sheet.getRange("A1").values = [[title]];
  sheet.getRange("A1").format = { fill: "#173F63", font: { bold: true, color: "#FFFFFF", size: 14 }, horizontalAlignment: "left" };
  sheet.getRange(`A2:${lastColumn}2`).values = [headers];
  sheet.getRange(`A2:${lastColumn}2`).format = { fill: "#D9EAF7", font: { bold: true, color: "#18313F" }, wrapText: true };
  sheet.getRange(`A3:${lastColumn}${endRow}`).values = body;
  sheet.getRange(`A2:${lastColumn}${endRow}`).format.borders = { preset: "all", style: "thin", color: "#DCE5EA" };
  sheet.getRange(`A:${lastColumn}`).format.columnWidth = 18;
  sheet.getRange(`A2:${lastColumn}${endRow}`).format.wrapText = true;
  sheet.freezePanes.freezeRows(2);
  sheet.showGridLines = false;
  sheet.tables.add(`A2:${lastColumn}${endRow}`, true, `${sheetName.replaceAll(" ", "")}Table`).style = "TableStyleMedium2";
  return workbook;
}

async function exportWorkbook(workbook, filename) {
  const file = await SpreadsheetFile.exportXlsx(workbook);
  await file.save(path.join(destination, filename));
}

await exportWorkbook(addTableWorkbook("Data Quality Log", "Data Quality Log", qualityRows), "data_quality_log.xlsx");
await exportWorkbook(addTableWorkbook("Reconciliation", "Reconciliation Report", reconciliationRows), "reconciliation_report.xlsx");
console.log(`Created control workbooks in ${destination}`);
