import express, { Request, Response } from "express";

const app = express();
const PORT = process.env.PORT ?? 8090;

function init() {

  app.get("/health", (req: Request, res: Response) => {
    res.status(200).json({
      message: "Working / route",
    });
  });

  app.listen(PORT, () => {
    console.log(`server is running on ${PORT}...`);
  });
  
}

init();
