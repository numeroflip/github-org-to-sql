import fs from "fs";

export const writeLine = (writeStream: fs.WriteStream, line: string) => {
  if (!writeStream.write(line)) {
    return new Promise<void>((resolve) => writeStream.once("drain", resolve));
  }
  return Promise.resolve();
};
