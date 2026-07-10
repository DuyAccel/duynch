---
title: "Automate Website Deployment with CD Pipeline"
date: 2024-09-01T13:59:07Z
draft: false
author: Nguyễn Châu Hiếu Duy
tags: ['CI/CD', 'Docker', 'Portfolio']
summary: A beginner's guide to deploying a website and setting up a CI/CD pipeline.
image: "/images/website-with-cd-pipeline/github-action.png"
---
*ps: the website I built back then has been completely revamped into what it is today :D*

No more worrying about the classic "It works on my machine" phrase. In this article, I will share how I created and published a website on an AWS EC2 instance completely automatically and for free. The moment you push code to a GitHub repository, the website will be automatically built and deployed to production. :D  

## Technologies Used
- Docker - for containerizing the code.
- GitHub Actions - for the CD pipeline.
- Hugo + Hugo-profile theme - building a website using just Markdown is amazing.
- AWS EC2 - to host the final website.

Needless to say, Docker has become a standard among developers in recent years. As for the CI/CD tool, although I have set up and used Jenkins for a while, it was quite complex and consumed a lot of resources. So this time, I chose GitHub Actions, which offers over 2000 free minutes per month—more than enough for a personal project.
Next is Hugo, a tool that allows you to build static websites using markdown files, making it incredibly friendly for low-code developers. 
Taking advantage of a 1-year AWS free trial account, I will host my product there.

## Building the Website
![](/images/website-with-cd-pipeline/hugo.png)
### Installing Hugo

I'll be using Hugo's prebuilt binary, which you can easily download from the [Hugo release page](https://github.com/gohugoio/hugo/releases). Note that you must download the **extended** version to use Hugo themes. Here are the commands I used to download and use Hugo. 

```bash
mkdir ~/hugo-install
cd ~/hugo-install
wget https://github.com/gohugoio/hugo/releases/download/v0.133.1/hugo_extended_0.133.1_linux-amd64.tar.gz
tar -xzf hugo_extended_0.133.1_linux-amd64.tar.gz
chmod +x hugo
# Use root permission to copy hugo binary file to PATH folder.
sudo cp hugo /usr/local/bin/    
```

Check out the [Hugo guide](https://gohugo.io/getting-started/quick-start/) to design your own website content. Hugo has a diverse collection of community-contributed themes. Here, I use the `Portfolio` theme, which comes preconfigured to simplify the development process.

This article will focus on configuring the CI/CD pipeline, so let's move on.

> *Note: If you're developing inside a container (like me), you must bind Hugo's service to the `0.0.0.0` IP. That way, you can map the port to the host and access the website.*
```bash
hugo server --bind 0.0.0.0
```
### Creating the Docker Image
![](/images/website-with-cd-pipeline/docker.png)
After building the website, let's pack it into a container. As recommended by Hugo, you shouldn't use their built-in web server in production. So, I used Nginx as the web server for my product. Below is a multi-stage **Dockerfile** used to build and copy the files rendered by Hugo into a clean Nginx image. This reduces the Docker image size and minimizes dependencies, making it safer.
```dockerfile
# Build stage.
FROM alpine:3.20.2 AS builder

# Install needed dependencies for hugo.
RUN apk update && \
    apk add --no-cache gcompat libstdc++

WORKDIR /app

# Copy source code to image (change ./devel to your folder).
COPY ./devel . 

# Install hugo.
RUN cd hugo-install && \
    tar -xzf hugo_extended_0.133.0_linux-amd64.tar.gz && \
    chmod +x hugo && \
    mv hugo /bin/ 

# Clear old build. Then, rebuild website.
RUN rm -rf public && \
    hugo

# Production stage. 
FROM nginx:1.27.1-alpine

# Copy necesary files from build stage
COPY --from=builder /app/public /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```
## Configuring the CD Pipeline
![](/images/website-with-cd-pipeline/github-action.png)

To use GitHub Actions, you need to create a `.github/workflows` folder at the root of your project (in the same directory as `.git`). Then, add a `.yml` file inside, which will hold the configuration for the CI/CD pipeline.

I designed a pipeline with the following 4 stages: 
- Checkout source code from the repository.
- Build the image.
- Push the image to Docker Hub.
- SSH into the server, pull the image, and run the container.

Here is the `CD.yml` file containing these steps:
```yaml
name: Create and publish a Docker image
on:
  push:
    branches: ['main']
  workflow_dispatch:

env:
  REGISTRY: docker.io 
  USER_NAME: duyaccel
  IMAGE_NAME: duyaccel/personal-web
  SSH_KEY: ${{ secrets.SSH_KEY }}
  SERVER: ${{ secrets.SERVER }}
  SV_USER: ${{ secrets.SV_USER }}
  

jobs:
  continuous_deployment:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      attestations: write
      id-token: write
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          submodules: 'true'

      - name: Log in to the Container registry
        uses: docker/login-action@65b78e6e13532edd9afa3aa52ac7964289d1a9c1
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ env.USER_NAME }}
          password: ${{ secrets.DOCKER_TOKEN }}

      - name: Extract metadata (tags, labels) for Docker
        id: meta
        uses: docker/metadata-action@9ec57ed1fcdbf14dcef7dfbe97b2010124a938b7
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}

      - name: Build and push Docker image
        id: push
        uses: docker/build-push-action@f2a1d5e99d037542a71f64918e516c093c6f3fc4
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}

      - name: Deploy website
        run: |
          echo "$SSH_KEY" > private_key && chmod 600 private_key
          ssh -o StrictHostKeyChecking=no -i private_key ${SV_USER}@${SERVER} '
            docker rm -f portfolio || true
            docker image prune -af
            docker run -d --name portfolio -p 80:80 duyaccel/personal-web:main
           '
```
If you're wondering where these **secrets** come from:
```bash
  ${{ secrets.DOCKER_TOKEN }}       # Token to access Docker Hub
  SSH_KEY: ${{ secrets.SSH_KEY }}   # SSH key to access the server
  SERVER: ${{ secrets.SERVER }}     # Server IP address
  SV_USER: ${{ secrets.SV_USER }}   # Username on the server
```
![](/images/website-with-cd-pipeline/secrets.png)

The answer is GitHub Secrets. You need to add them to your GitHub repository before executing the pipeline. First, go to `your repository -> Settings -> 
Security -> Secrets and variables -> Actions`, then add the secrets mentioned above. 

## Executing the Pipeline

Once `.github/workflows/CD.yml` is in place, I just need to push code to the repository and wait for the pipeline to execute. Grab a cup of tea and monitor the progress on the `Actions` tab of your GitHub repository. 

![](/images/website-with-cd-pipeline/workflow.png)

If everything goes smoothly, you can find your website right in your browser by searching for your IP address/domain name. To be completely sure, SSH into the server to check the status of your container.
![](/images/website-with-cd-pipeline/website.png)
## Conclusion

In this article, I presented how I used GitHub Actions to create a CD pipeline for my personal portfolio website. Basically, the website and pipeline are working fine, but it would be better to have a reverse proxy in front to handle SSL and routing traffic when hosting more than one application.


I will add these points to my `Future Todo List`. For now, thank you for taking the time to read this article. See you in the next ones.

---
References:
- https://gohugo.io/documentation
- https://docs.github.com/en/Actions
