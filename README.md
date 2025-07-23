# Projeto: CI/CD com GitHub Actions

GitHub Actions e ArgoCD são ferramentas essenciais no CI/CD moderno, automatizando deploys e infraestrutura via Git. Dominar essas práticas é crucial para profissionais de DevOps, SRE, Cloud e desenvolvimento ágil. E por isso foi feito esse projeto visando o aprendizado.

- [Objetivo](#objetivo)
- [Pré-requisitos](#pré-requisitos)
1. [Criar a aplicação FastAPI](#1-criar-a-aplicação-fastapi)
2. [Criar o GitHub Actions (CI/CD)](#2-criar-o-github-actions-cicd)
3. [Repositório Git com os manifests do ArgoCD](#3-repositório-git-com-os-manifests-do-argocd)
4. [Criar o App no ArgoCD](#4-criar-o-app-no-argocd)
5. [Acessar e testar a aplicação localmente](#5-acessar-e-testar-a-aplicação-localmente)

---

## ✅Objetivo

Automatizar o ciclo completo de desenvolvimento, build, deploy e 
execução de uma aplicação FastAPI simples, usando GitHub Actions para 
CI/CD, Docker Hub como registry, e ArgoCD para entrega contínua em 
Kubernetes local com Rancher Desktop.

---

## Pré-requisitos

* Conta no GitHub (repo público) 
* Conta no Docker Hub com token de acesso  
* Rancher Desktop com Kubernetes habilitado  
* kubectl configurado corretamente (kubectl get nodes)  
* ArgoCD instalado no cluster local  
* Git instalado  
* Python 3 e Docker instalados

---

## 1. Criar a aplicação FastAPI

Nosso primeiro passo é a criação do nosso repositório, no caso esse repo em que estamos. E logo após, criamos a nossa aplicação main.py:
```
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Seu texto desejado"}
```

Em seguida, nosso arquivo Dockerfile:

![1](/Prints/1.png)

```
python:3.12-alpine3.19

RUN apk add --no-cache gcc musl-dev libffi-dev

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir fastapi uvicorn[standard]

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
```

Nosso Dockerfile empacota a aplicação, tornando-a portável e pronta para rodar em qualquer ambiente compatível com Docker/Kubernetes. Após isso, vamos criar outro repositório [manifests-Kubernetes](https://github.com/LucasLaranja/manifests-Kubernetes) para nossos yaml, em breve vamos voltar nele.

---

## 2. Criar o GitHub Actions (CI/CD)

Agora vamos para a criação do nosso yaml, crie uma pasta chamada .github no repositório, e outra dentro da mesma, chama workflows, e dentro delas nosso yaml, **isso será importante para usar o github actions**. Agora vamos editar nosso yaml:

```
name: actions pipeline

on:
  push:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      with:
        submodules: true

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2

    - name: Log in to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: ${{ secrets.DOCKER_USERNAME }}/app-projeto:${{ github.sha }}

    - name: Clone manifests repository
      uses: actions/checkout@v3
      with:
        repository: {Seu github}/{Repositório com os Yaml}
        path: manifests
        token: ${{ secrets.PERSONAL_ACCESS_TOKEN }}

    - name: Update image tag in deployment manifest
      run: |
        sed -i "s|image: .*|image: ${{ secrets.DOCKER_USERNAME }}/app-projeto:${{ github.sha }}|g" manifests/deployment.yaml

    - name: Commit and push updated manifests
      run: |
        cd manifests
        git config user.name "github-actions"
        git config user.email "github-actions@github.com"
        git add deployment.yaml
        git commit -m "Update image tag to ${{ github.sha }}"
        git push origin main
```

Agora vamos criar nossos secrets para a integração com o Dockerhub:

![2](/Prints/2.png)

* Para chegar nesse caminho vá no repositório da aplicação, settings, secrets and variables e por fim actions.

Vamos a criação das variavéis:

![3](/Prints/3.png)

**DOCKER_USERNAME: Seu usuário do Dockerhub**

**DOCKER_PASSWORD: Sua senha/token do Dockerhub**

**PERSONAL_ACCESS_TOKEN: token GitHub com permissão para push no repo dos manifests**

* No meu caso utilizei o PAT(Personal Acess Token), mas pode também ser utilizado o SSH. Caso não saiba criar o PAT, vá no repositório [Projeto: GitOps na prática](https://github.com/LucasLaranja/ProjetoGitOps) e vá em extras, para aprender como criar passo a passo.

Agora vamos no actions ver como está e em seguida vamos ver no Dockerhub:

![4](/Prints/4.png)

![5](/Prints/5.png)

---

## 3. Repositório Git com os manifests do ArgoCD

Lembra do nosso outro repositório, então vamos usá-lo nessa etapa. Criaremos dois yaml nele, sendo um o deployment e outro o service:

![6](/Prints/6.png)

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-projeto
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-projeto
  template:
    metadata:
      labels:
        app: app-projeto
    spec:
      containers:
      - name: app-projeto
        image: {seu Usuário do Dockerhub}/app-projeto:latest

        ports:
        - containerPort: 80
```

![7](/Prints/7.png)

```
apiVersion: v1
kind: Service
metadata:
  name: app-projeto
spec:
  type: ClusterIP
  selector:
    app: app-projeto
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

* Não se esqueça de trocar os nomes pelo nome da sua aplicação e seu usuário do Dockerhub

* Esse repositório será usado pelo ArgoCD para sincronizar o deploy.

## 4. Criar o App no ArgoCD

Agora vamos utilizar nosso ArgoCD:

![8](/Prints/8.png)

Agora vamos colocar na porta 8080, para utilizarmos:

![9](/Prints/9.png)

![10](/Prints/10.png)

Agora precisamos realizar o login, o username é admin, e para descobrir a senha, no meu caso, eu utilizei o comando:

```
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}")))
```

![11](/Prints/11.png)

Vamos a criação da aplicação, siga os passos das imagens:

![12](/Prints/12.png)

* Não se esqueça de trocar o nome para sua aplicação

![13](/Prints/13.png)

* Link do **seu** repositório

* Path: .

* Cluster: in-cluster

Clique em create e aguarde terminar de sincronizar:

![14](/Prints/14.png)

![15](/Prints/15.png)

---

## 5. Acessar e testar a aplicação localmente