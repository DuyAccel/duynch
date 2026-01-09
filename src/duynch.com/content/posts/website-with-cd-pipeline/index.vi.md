---
title: "Tự động triển khai website với CD pipeline"
date: 2024-09-01T13:59:07Z
draft: false
author: Nguyễn Châu Hiếu Duy
tags: ['CI/CD', 'Docker', Portfolio]
summary: Bài viết vỡ lòng khi mình bắt đầu tìm hiểu về deploy và CI/CD pipeline.
toc:
---
*ps: website hồi đó mình làm đã bị đập đi xây lại thành như bây giờ nha :D*

Không còn lo về câu nói "Máy tui nó chạy bình thường mà". Trong bài viết này, tôi sẽ chia cách mà bản thân đã tạo và publish một website trên một AWS EC2 instance mộ cách hoàn toàn tự động và miễn phí. Tại khoảnh khắc bạn push code lên github repository, website sẽ được tự động build và triển khai lên production. :D  

## Các công nghệ được sử dụng
- Docker - dùng để đóng gói container code.
- Github Action - cho CD pipeline.
- Hugo + Hugo-profile theme - build website bằng README.md quá đã.
- AWS EC2 - dùng để host website thành phẩm.

Không cần phải nói thì Docker gần như đã trở thành một tiêu chuẩn trong giới lập trình viên trong những năm gần đây. Còn về công cụ CI/CD, mặc dù đã từng setup và sử dụng jenkins một thời gian nhưng nó khá phức tạp và tốn nhiều tài nguyên. Vậy nên, lần này tôi lựa chọn Github Action với hơn 2000 phút chạy miễn phí mỗi tháng cho 1 dự án cá nhân thì quá là dư rồi.
Tiếp theo là Hugo, một công cụ cho phép build, dựng những trang web tĩnh bằng các file markdown, quá là thân thiện với dân low-dev. 
Tranh thủ khoảng thời gian 1 năm trial của AWS account, tôi sẽ host sản phẩm của mình lên đó.

## Xây dựng website nào
![](/posts/website-with-cd-pipeline/hugo.png)
### Cài đặt Hugo

Tôi sẽ dùng prebuilt binary của Hugo, bạn cũng có thể dễ dàng tải nó từ [hugo release page](https://github.com/gohugoio/hugo/releases). Một lưu ý là phải download phiên bản **extended** để có thể sử dụng các theme của Hugo. Sau đây là các command tôi dùng để tải và sử dụng Hugo. 

```
mkdir ~/hugo-install
cd ~/hugo-install
wget https://github.com/gohugoio/hugo/releases/download/v0.133.1/hugo_extended_0.133.1_linux-amd64.tar.gz
tar -xzf hugo_extended_0.133.1_linux-amd64.tar.gz
chmod +x hugo
# Use root permission to copy hugo binary file to PATH folder.
sudo cp hugo /usr/local/bin/    
```

Hãy tham khảo [Hugo guide](https://gohugo.io/getting-started/quick-start/) để tự thiết kế nội dung website. Hugo có một bộ sưu tập theme rất đa dạng do cộng đồng đóng góp. ở đây tôi sử dụng theme `Portfolio` với giao diện được cấu hình sẵn nhằm đơn giản hóa quá trình phát triển.

Bài viết này sẽ tập trung vào việc cấu hình CI/CD pipeline nên chúng ta tiếp tục nào.

> *Lưu ý nếu bạn dev ngay bên trong container (giống tôi) thì phải bind service của hugo lên ip 0.0.0.0 nhé. Bằng cách đó thì ta mới có thể map port vào host và truy cập vào webiste*
```
hugo server --bind 0.0.0.0
```
### Tạo Docker image
![](/posts/website-with-cd-pipeline/docker.png)
Sau khi đã xây dựng website, hãy đóng gói nó vào container nào. Theo như khuyến nghị của Hugo, không nên dùng webservice tích hợp sẵn trong binary của họ trên production. Vậy nên, tôi sử dụng nginx làm webservice cho sản phẩm của mình. Dưới đây là **Dockerfile** dùng multi-stage để build và copy những file do Hugo render ra vào một nginx image trống. Bằng cách này, ta có thể giảm nhẹ dung lượng của docker image và ít dependency trong image hơn cũng an toàn hơn.
```
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
## Cấu hình CD pipeline
![](/posts/website-with-cd-pipeline/github-action.png)

Để sử dụng Github Action, ta sẽ cần tạo folder `.github/workflows` tạo root của project (cùng folder cha với `.git`). Sau đó, thêm một file `Yaml` vào trong, đây sẽ là file thiết lập cấu hình cho CI/CD pipeline.

Tôi sẽ thiết kế pipeline gồm 4 giai đoạn sau: 
- Tải source code từ repository.
- Build image.
- Đẩy image vào docker hub.
- SSH vào trong server, kéo image về rồi chạy container.

Sau đây là file `CD.yml` chứa các bước trên:
```
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
Nếu bạn thắc mắc những **secret** này ở đâu ra:
```
  ${{ secrets.DOCKER_TOKEN }}       # Token dùng để access dockerhub
  SSH_KEY: ${{ secrets.SSH_KEY }}   # SSH key để truy cập server
  SERVER: ${{ secrets.SERVER }}     # IP của server
  SV_USER: ${{ secrets.SV_USER }}   # Username trên server
```
![](/posts/website-with-cd-pipeline/secrets.png)

Thì đáp án đó là github secrets, ta sẽ cần thêm chúng vào trong github repository trước khi thực thi pipeline. Đầu tiên hãy vào `your repository -> Settings -> 
Security -> Secrets and variables -> Actions` sau đó thêm các secret trên vào. 

## Thực thi pipeline

Khi đã có `.github/workflows/CD.yml`, tôi chỉ cần push code lên repository và chờ cho pipeline thực thi. Hãy nhâm nhi tách trà và theo dõi tiến độ trên tab `Actions` của repository trên github. 

![](/posts/website-with-cd-pipeline/workflow.png)

Nếu mọi chuyện suông sẻ, bạn sẽ tìm thấy website ngay trên browser bằng cách search ip address/domain name. Chắc ăn hơn thì hãy ssh vào server để kiểm tra tình trạng của container.
![](/posts/website-with-cd-pipeline/website.png)
## Kết luận

Trong bài viết này, tôi đã trình bày các mà mình dùng Github Action làm công cụ tạo cd pipeline cho portfolio website của bản thân. Về cơ bản website và pipeline hoạt động tốt, nhưng tốt hơn ta nên có một reverse proxy phía trước nhằm xử lý ssl, routing traffic khi ta có nhiều hơn 1 ứng dụng cần được host.


Tôi sẽ thêm các điểm trên vào `Todo List cho tương lai`, còn bây giờ, cảm ơn bạn đã dành thời gian đọc bài viết này. Hẹn gặp lại ở những bài viết tiếp theo.

---
References:
- https://gohugo.io/documentation
- https://docs.github.com/en/Actions
