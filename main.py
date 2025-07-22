from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Testando o texto mudando no app"}
