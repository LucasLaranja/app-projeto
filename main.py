from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Projeto actions da compass concluído com sucesso."}
