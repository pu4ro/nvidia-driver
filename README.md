# NVIDIA GPU Driver Offline Container

이 리포지토리는 GPU Operator를 위해 Ubuntu 22.04 기반의 NVIDIA 드라이버 컨테이너 이미지를 **오프라인 실행** 환경에서도 동작하도록 빌드하는 Dockerfile을 제공합니다.

## 개요

- **Repo Builder**: 필수 패키지(`linux-headers`, `linux-image`, `linux-modules`, `dkms`, `kmod`, `build-essential`) 및 의존성 `.deb` 파일을 다운로드하여 `/local-repo` 경량 APT 레포를 생성합니다.
- **Driver Builder**: NVIDIA 런파일(`.run`)을 `wget`으로 다운로드하고, DKMS 모듈을 빌드합니다.
- **Final Stage**: 빌드된 커널 모듈과 `/local-repo`를 복사한 뒤, 런타임 시 APT 소스가 오직 `/local-repo`를 가리키도록 설정하고, `nvidia-driver init` 스크립트를 오프라인 전용으로 덮어써서 외부 네트워크 없이 즉시 구동되도록 합니다.

## 전제조건

- Docker가 설치되어 있어야 합니다.
- GPU Operator와 호환되는 드라이버 버전 및 커널 버전을 확인하세요.

## 파일 구조

```text
Dockerfile.precompiled
offline-init.sh
```  

- **Dockerfile.precompiled**: 멀티스테이지 Dockerfile (repo-builder, driver-builder, final).
- **offline-init.sh**: 런타임 초기화 스크립트. GPU Operator가 요구하는 검증 플래그를 생성하고, 모듈만 로드합니다.

## 빌드 방법

1. 환경변수 설정:
   ```bash
   export DRIVER_VERSION=535.183.06
   export KERNEL_VERSION=5.15.0-119-generic
   export OS_TAG=ubuntu22.04
   export REGISTRY=your.registry.local
   ```

2. `offline-init.sh` 파일 준비:
   ```bash
   chmod +x offline-init.sh
   ```

3. 컨테이너 이미지 빌드:
   ```bash
   docker build \
     -f Dockerfile.precompiled \
     --build-arg DRIVER_VERSION=${DRIVER_VERSION} \
     --build-arg KERNEL_VERSION=${KERNEL_VERSION} \
     --build-arg OS_TAG=${OS_TAG} \
     -t ${REGISTRY}/nvidia/driver:${DRIVER_VERSION}-${KERNEL_VERSION}-${OS_TAG} \
     .
   ```

4. 레지스트리에 Push:
   ```bash
   docker push ${REGISTRY}/nvidia/driver:${DRIVER_VERSION}-${KERNEL_VERSION}-${OS_TAG}
   ```

## GPU Operator 설정 예시

Helm 차트나 manifest에서 아래와 같이 드라이버 리포지토리와 이미지를 지정하세요.

```bash
helm install gpu-operator nvidia/gpu-operator \
  --version v23.6.1 \
  --set driver.repository=${REGISTRY}/nvidia \
  --set driver.image=driver \
  --set driver.tag=${DRIVER_VERSION}-${KERNEL_VERSION}-${OS_TAG}
```

## 동작 검증

GPU Operator가 실행될 때 다음과 같은 메시지가 없어야 합니다.

```
nvidia-driver-ctr W: Failed to fetch http://archive.ubuntu.com/ubuntu/...
```

또한, `/run/nvidia/validations/.driver-ctr-ready` 파일이 생성되어야 정상 준비 상태로 판단됩니다.

---

위 내용을 기반으로 Dockerfile을 빌드 및 배포하면, **오프라인 환경에서도** GPU Operator의 NVIDIA 드라이버 컨테이너가 문제없이 동작합니다.

