export const createCsvHeader = (keys: readonly string[]) => keys.join(",");

export const csvValue = (v: unknown): string => {
  const s = String(v ?? "");
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

export const toCsvLine = <T extends Record<string, unknown>>(
  keys: ReadonlyArray<keyof T & string>,
  row: T
): string => keys.map((k) => csvValue(row[k])).join(",") + "\n"; 
