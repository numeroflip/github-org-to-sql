import fs from "fs/promises";

export const ensureDir = async (dir: string) => {
  await fs.mkdir(dir, { recursive: true });
};