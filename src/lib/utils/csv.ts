export const createCsvHeader = (keys: readonly string[]) => keys.join(",");

export const csvValue = (v: unknown): string => {
  const s = String(v ?? "");
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

export const createCsvLine = (values: ReadonlyArray<unknown>): string =>
  values.map(csvValue).join(",") + "\n";
