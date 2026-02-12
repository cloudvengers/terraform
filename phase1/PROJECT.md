# 3-Tier + Well-Architected 프로젝트

## 이 프로젝트는 뭐하는 거야?

AWS 위에 웹 애플리케이션을 올리는 **인프라**를 Terraform으로 구축한다.
단순히 돌아가게만 만드는 게 아니라, AWS가 권장하는 **Well-Architected 6대 원칙**을 전부 적용한다.

- **앱**: AWS 제공 샘플 앱 (인프라에 집중하기 위해 앱은 신경 안 씀)
- **IaC**: Terraform
- **리전**: us-east-1

---

## 전체 구조 (트래픽 흐름)

```
사용자
  │
  ▼
[CloudFront] ─ CDN, 정적 콘텐츠 캐싱
  │
  ▼
[WAF] ─ 악성 요청 차단 (SQL Injection, XSS 등)
  │
  ▼
[ALB] ─ 요청을 여러 EC2에 분산 (HTTPS, ACM 인증서)
  │
  ▼
[EC2 Auto Scaling Group] ─ 앱 서버 (트래픽에 따라 자동 증감)
  │                         ├── IAM Role로 AWS 서비스 접근
  │                         └── CloudWatch Agent로 메모리/디스크 모니터링
  │
  ▼
[ElastiCache] ─ 자주 쓰는 데이터 캐싱 (DB 부하 감소)
  │
  ▼
[RDS MySQL Multi-AZ] ─ 데이터 저장 (자동 백업, 장애 시 자동 전환)
```

### 알림 흐름

```
CloudWatch 알람 (CPU 90% 초과!) ──→ SNS Topic ──→ 이메일/SMS
Budgets (예산 초과!) ──────────────→ SNS Topic ──→ 이메일/SMS
ASG (인스턴스 증감!) ──────────────→ SNS Topic ──→ 이메일/SMS
```

### 로그 흐름

```
CloudTrail (API 감사 로그) ──→ S3 버킷 (로그 저장용)
VPC Flow Logs (네트워크 로그) ──→ S3 버킷 (로그 저장용)
ALB Access Logs (접속 기록) ──→ S3 버킷 (로그 저장용)
```

### 모니터링 통합

```
CloudWatch 메트릭 ──┐
CloudWatch Logs ────┤
CloudTrail 로그 ────┤──→ Managed Grafana (한 화면에서 전체 확인)
AWS Config ─────────┘
```

---

## 네트워크 구조

```
VPC (10.0.0.0/16)
├── Public Subnet (AZ-a, AZ-b)    ← ALB, NAT Gateway
├── Private Subnet (AZ-a, AZ-b)   ← EC2 (앱 서버)
└── Private Subnet (AZ-a, AZ-b)   ← RDS, ElastiCache (DB 계층)
```

- **Public**: 인터넷에서 접근 가능 (ALB가 여기 있음)
- **Private (App)**: 인터넷 직접 접근 불가, NAT Gateway 통해 외부 통신
- **Private (DB)**: 인터넷 접근 완전 차단, 앱 서버에서만 접근 가능

---

## Well-Architected 6대 원칙 — 왜 이 서비스를 쓰는가

### 1. 운영 우수성 — "문제를 빨리 발견하고 대응할 수 있는가?"

| 서비스 | 하는 일 |
|--------|---------|
| CloudWatch | EC2 CPU, 메모리, ALB 에러율 등 **모니터링** + 임계치 초과 시 **알람** |
| CloudWatch Agent | EC2 내부 **메모리/디스크** 모니터링 (기본 CloudWatch는 CPU만 봄) |
| SNS | CloudWatch 알람을 **이메일/SMS로 전달**하는 알림 통로 |
| CloudTrail | 누가 언제 어떤 AWS API를 호출했는지 **감사 로그** 기록 |
| AWS Config | 리소스 설정이 변경되면 **기록** (예: 보안그룹 규칙이 바뀌면 추적) |
| Systems Manager | EC2에 SSH 없이 접속 (Session Manager) + OS 패치 자동화 |
| Managed Grafana | CloudWatch + CloudTrail + Config를 **한 화면에 통합** 모니터링 |

### 2. 보안 — "허가된 사람/요청만 접근하는가?"

| 서비스 | 하는 일 |
|--------|---------|
| IAM Role + Instance Profile | EC2가 AWS 서비스에 접근할 **권한 부여** (SSM, CloudWatch, Secrets Manager) |
| ACM | ALB에 **HTTPS 인증서** 적용 (무료) |
| WAF | SQL Injection, XSS 같은 **웹 공격 차단** |
| Security Groups + NACL | 계층별 **네트워크 접근 제어** (ALB→EC2→RDS만 허용) |
| Secrets Manager | DB 비밀번호를 코드에 안 넣고 **안전하게 저장/자동 교체** |
| KMS | RDS 데이터를 **암호화** (저장 시 암호화) |
| VPC Flow Logs | 네트워크 트래픽 **로그 기록** (비정상 접근 탐지) |
| ALB Access Logs | ALB를 거치는 모든 요청 **기록** (누가, 언제, 어떤 URL) |
| GuardDuty | AWS 계정 전체 **위협 자동 탐지** (무단 접근, 악성 IP 등) |
| S3 (로그 저장용) | CloudTrail, Flow Logs, ALB 로그의 **저장소** |

### 3. 안정성 — "장애가 나도 서비스가 계속 되는가?"

| 서비스 | 하는 일 |
|--------|---------|
| Multi-AZ (ALB, ASG, RDS) | 가용영역 하나가 죽어도 **다른 AZ에서 계속 운영** |
| RDS 자동 백업 | 매일 자동 백업 + 특정 시점으로 **복원 가능** |
| S3 백업 | RDS 스냅샷 외 추가 백업 저장소 |
| Route 53 Health Check | 엔드포인트 상태 확인 → 장애 시 **자동 DNS 전환** |

### 4. 성능 효율성 — "트래픽이 늘어도 빠르게 응답하는가?"

| 서비스 | 하는 일 |
|--------|---------|
| CloudFront | 전 세계 엣지에서 정적 콘텐츠 **캐싱** → 응답 속도 향상 |
| ElastiCache | DB 조회 결과를 **메모리에 캐싱** → DB 부하 감소 |
| ASG Target Tracking | CPU 70% 넘으면 EC2 **자동 추가**, 내려가면 **자동 제거** |

### 5. 비용 최적화 — "돈을 낭비하지 않는가?"

| 서비스 | 하는 일 |
|--------|---------|
| 태그 전략 | 모든 리소스에 태그 → **비용 추적** (어디서 돈이 나가는지 파악) |
| Budgets + SNS | 예산 초과 시 **이메일/SMS 알림** |
| 적정 사이징 | 필요 이상으로 큰 인스턴스 안 씀 |

### 6. 지속 가능성 — "자원을 효율적으로 쓰는가?"

| 서비스 | 하는 일 |
|--------|---------|
| Graviton (t4g) | ARM 기반 인스턴스 → 같은 성능에 **전력 소비 40% 감소** |
| S3 Intelligent-Tiering | 안 쓰는 데이터는 자동으로 **저렴한 스토리지로 이동** |

---

## 작업 순서

### Phase 1 — 뼈대 (3-Tier가 동작하는 최소 구성)

> 목표: 사용자가 브라우저에서 앱에 접속할 수 있는 상태

| 순서 | 파일 | 내용 | 상태 |
|------|------|------|------|
| 1 | main.tf | Provider, 기본 태그 | ✅ 완료 |
| 2 | vpc.tf | VPC, 서브넷 6개 | ✅ 완료 |
| 3 | igw.tf | Internet Gateway | ✅ 완료 |
| 4 | nat.tf | NAT Gateway x2, EIP x2 | ✅ 완료 |
| 5 | route.tf | Route Table (Public 1, Private App 2, Private DB 2) | ✅ 완료 |
| 6 | security.tf | Security Groups (ALB, App, DB) | ✅ 완료 |
| 7 | iam.tf | EC2 IAM Role + Instance Profile (정책 없음, asg.tf에서 참조용) | ⬜ 미작성 |
| 8 | alb.tf | ALB, Target Group, Listener | ⬜ 미작성 |
| 9 | asg.tf | Launch Template, ASG, Scaling 정책 | ⬜ 미작성 |
| 10 | rds.tf | RDS MySQL, Subnet Group | ⬜ 미작성 |

### Phase 2 — 보안 강화

> 목표: 외부 공격 방어 + 데이터 암호화 + 접근 통제 + 로그 수집

| 순서 | 파일 | 내용 |
|------|------|------|
| 11 | s3-logs.tf | 로그 저장용 S3 버킷 (CloudTrail, Flow Logs, ALB 로그) |
| 12 | acm.tf | HTTPS 인증서 |
| 13 | waf.tf | 웹 방화벽 규칙 |
| 14 | secrets.tf | DB 비밀번호 관리 (Secrets Manager + KMS) |
| 15 | iam.tf 수정 | Secrets Manager 읽기 권한 추가 |
| 16 | flowlogs.tf | VPC 트래픽 로그 → S3 |
| 17 | alb.tf 수정 | ALB Access Logs 활성화 → S3 |
| 18 | guardduty.tf | 위협 탐지 활성화 |

### Phase 3 — 안정성 + 성능

> 목표: 장애 대응 + 캐싱으로 성능 향상

| 순서 | 파일 | 내용 |
|------|------|------|
| 19 | rds.tf 수정 | Multi-AZ 활성화, 자동 백업 설정 |
| 20 | cloudfront.tf | CDN 배포 |
| 21 | elasticache.tf | Redis/Memcached 캐시 |
| 22 | route53.tf | Health Check (도메인 있을 경우) |

### Phase 4 — 운영 + 모니터링

> 목표: 문제 발생 시 빠른 감지와 대응 → Grafana로 한 화면에서 전체 확인

| 순서 | 파일 | 내용 |
|------|------|------|
| 23 | sns.tf | SNS Topic + 이메일 구독 (알림 통로) |
| 24 | iam.tf 수정 | CloudWatch Agent + SSM 정책 추가 |
| 25 | cloudwatch.tf | 대시보드, 알람 → SNS, 로그 그룹, CloudWatch Agent 설정 |
| 26 | cloudtrail.tf | API 감사 로그 → S3 |
| 27 | config.tf | 리소스 변경 추적 |
| 28 | ssm.tf | Session Manager, 패치 관리 |
| 29 | grafana.tf | Managed Grafana workspace + CloudWatch/CloudTrail/Config 데이터 소스 연결 |

### Phase 5 — 비용 + 지속 가능성

> 목표: 비용 관리 + 효율적 자원 사용

| 순서 | 파일 | 내용 |
|------|------|------|
| 30 | budgets.tf | 예산 알림 → SNS |
| 31 | asg.tf 수정 | Graviton(t4g) 인스턴스로 전환 |
| 32 | s3.tf | Intelligent-Tiering 백업 버킷 |
