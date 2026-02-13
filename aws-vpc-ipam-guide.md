# AWS VPC IPAM 정리

## IPAM이란?

IPAM(IP Address Manager)은 AWS에서 VPC의 CIDR을 중앙에서 자동으로 관리하는 기능이다.

직접 `10.0.0.0/16`처럼 CIDR을 수동으로 정하지 않고,
IPAM 풀(Pool)에서 사용 가능한 대역을 자동으로 할당받아 사용할 수 있다.

대규모 환경에서:
- CIDR 충돌 방지
- 리전/계정 간 IP 관리 일관성 유지
- IP 사용 현황 추적

을 위해 사용한다.

---

## 핵심 구성요소

### Scope (범위)
- IPAM 내 최상위 컨테이너
- IPAM 생성 시 **Private Scope**와 **Public Scope** 2개가 자동 생성됨
- Private Scope → 인터넷에 노출되지 않는 프라이빗 IP 공간
- Public Scope → 인터넷에 광고 가능한 퍼블릭 IP 공간

### Pool (풀)
- 연속된 IP 주소 범위(CIDR)의 모음
- Scope 안에 생성하며, 부모/자식 풀 구조로 계층화 가능
- 예: 최상위 풀 → 리전별 풀 → dev/prod 풀

### Allocation (할당)
- Pool에서 리소스(VPC 등)로 CIDR을 할당하는 것
- VPC 생성 시 IPAM Pool을 지정하면 자동으로 CIDR이 할당됨

---

## 계층 구조

```
IPAM
├── Private Scope (자동 생성)
│   └── Top-level Pool (예: 10.0.0.0/8)
│       ├── Regional Pool - us-east-1 (예: 10.1.0.0/16)
│       │   ├── Dev Pool (예: 10.1.0.0/20)
│       │   └── Prod Pool (예: 10.1.16.0/20)
│       └── Regional Pool - ap-northeast-2 (예: 10.2.0.0/16)
└── Public Scope (자동 생성)
    └── Public Pool (BYOIP 또는 Amazon 제공 IPv6)
```

---

## 티어

| 티어 | 설명 |
|------|------|
| Free | 기본 IP 주소 관리 기능 |
| Advanced | 고급 기능 포함 (기본값), 추가 비용 발생 |

---

## AWS Organizations 통합

- 조직 전체의 IP 주소 사용량 모니터링 가능
- 멤버 계정 간 IP 주소 풀 공유 가능 (AWS RAM 사용)
- 통합 시 `AWSServiceRoleForIPAM` 서비스 연결 역할이 자동 생성됨

---

## 참고 문서

- [What is IPAM?](https://docs.aws.amazon.com/vpc/latest/ipam/what-it-is-ipam.html)
- [How IPAM works](https://docs.aws.amazon.com/vpc/latest/ipam/how-it-works-ipam.html)
- [IPAM - AWS Prescriptive Guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/robust-network-design-control-tower/ipam.html)
