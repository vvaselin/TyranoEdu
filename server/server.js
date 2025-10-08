import express from "express";
import fetch from "node-fetch";
import dotenv from "dotenv";
dotenv.config();

const app = express();
app.use(express.json());

// ← ルート階層ごと配信（index.html, tyrano/, data/ 全部アクセス可能）
app.use(express.static("../"));

app.post("/api/chat", async (req, res) => {
  const { message } = req.body;

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${process.env.OPENAI_API_KEY}`
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "あなたはC++講師です。" },
        { role: "user", content: message }
      ]
    })
  });

  const data = await response.json();
  res.json({ text: data.choices?.[0]?.message?.content || "（応答なし）" });
});

app.listen(8080, () => console.log("Server running → http://localhost:8080"));
