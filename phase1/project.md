# project.md

## 1. 개념 및 구조

Terraform으로 AWS에 3-Tier 웹 애플리케이션 인프라를 구축한다.
Phase 1에서 최소 동작 뼈대를 만들고, Phase 2~7에서 Well-Architected Framework 6대 원칙을 하나씩 적용한다.

- IaC: Terraform
- 리전: us-east-1
- 앱: AWS 샘플 앱 (인프라 집중)

### 3계층 정의

**Web 계층** — 사용자 요청의 진입점. Public Subnet에 위치.
- ALB가 정상 EC2 인스턴스에만 요청 분산
- (Phase 2) WAF, ACM, HTTPS 추가
- (Phase 4) CloudFront CDN 추가

**App 계층** — 비즈니스 로직 처리. Private App Subnet에 위치.
- EC2 인스턴스가 애플리케이션 실행
- Launch Template: AMI(AL2023 SSM Param), t3.micro, User Data, IAM Role, SG
- ASG: min:1, max:3, desired:2, 2AZ 분산, CPU 70% Target Tracking
- SSM Session Manager로 접속 (SSH 키 불필요)
- (Phase 2) Secrets Manager로 DB 자격증명 조회
- (Phase 4) ElastiCache Redis 연결
- (Phase 7) Graviton t4g.micro 전환

**DB 계층** — 데이터 영구 저장. Private DB Subnet에 위치.
- RDS MySQL: Single-AZ (Phase 3에서 Multi-AZ)
- (Phase 2) KMS 암호화, Secrets Manager
- (Phase 3) Multi-AZ, 자동 백업 7일
- (Phase 4) ElastiCache Redis 캐싱

### 네트워크

```
VPC 10.0.0.0/16
├── Public    AZ-a 10.0.1.0/24  │ AZ-b 10.0.2.0/24   ← ALB, NAT GW
├── Priv-App  AZ-a 10.0.11.0/24 │ AZ-b 10.0.12.0/24  ← EC2
└── Priv-DB   AZ-a 10.0.21.0/24 │ AZ-b 10.0.22.0/24  ← RDS, ElastiCache
```

- IGW → Public Subnet 인터넷 연결
- NAT GW x2 (AZ별) → Private App Subnet 외부 통신
- Private DB Subnet → 인터넷 접근 차단, App에서만 접근
- Route Table 5개: Public 1, Private App 2(AZ별 NAT), Private DB 2
- Security Group 4개: ALB(80/443), App(ALB에서만), DB(App에서만), Cache(App에서만)

### 흐름도

```
[요청]  사용자 → (CloudFront) → (WAF) → ALB → EC2(ASG)
[데이터] EC2 → (ElastiCache) 또는 EC2 → RDS
[알림]  CloudWatch/Budgets/ASG → SNS → 이메일
[로그]  CloudTrail/FlowLogs/ALB Logs → S3
[통합]  CloudWatch+CloudTrail+Config → Grafana
```

괄호()는 Phase 1 이후 추가되는 서비스.

---

## 2. Phase 구조

| Phase | 원칙 | 핵심 목표 | 전제조건 |
|-------|------|-----------|----------|
| 1 | 최소 뼈대 | ALB → EC2 → RDS 동작 | 없음 |
| 2 | 보안 (Security) | 암호화 + 접근 통제 + 로그 수집 | Phase 1 |
| 3 | 안정성 (Reliability) | 장애 자동 복구 + 백업 | Phase 2 |
| 4 | 성능 효율성 (Performance Efficiency) | CDN + 캐싱 + 응답 속도 | Phase 2 |
| 5 | 운영 우수성 (Operational Excellence) | 모니터링 + 알림 + 감사 | Phase 2 |
| 6 | 비용 최적화 (Cost Optimization) | 예산 관리 + 스토리지 절감 | Phase 5 |
| 7 | 지속 가능성 (Sustainability) | Graviton 전환 + 자원 효율화 | Phase 1 |

---

## 3. Phase별 상세

### Phase 1 — 최소 뼈대

**목표**: 브라우저에서 ALB DNS로 접속 → EC2 샘플 앱 응답 → RDS 연결 확인

**서비스**: VPC, Subnet x6, IGW, NAT GW x2, RT x5, SG x4, IAM Role, ALB, EC2(LT+ASG), RDS MySQL

**TODO**:
- [ ] `main.tf` — Provider(AWS, us-east-1), 공통 태그(Project, Environment, ManagedBy)
- [ ] `vpc.tf` — VPC 10.0.0.0/16, 서브넷 6개, DNS 호스트네임 활성화
- [ ] `igw.tf` — IGW + VPC 연결
- [ ] `nat.tf` — EIP x2 + NAT GW x2 (AZ별)
- [ ] `route.tf` — RT 5개 + 서브넷 연결
- [ ] `security.tf` — SG 4개 (ALB:80/443, App:ALB→앱포트, DB:App→3306, Cache:App→6379)
- [ ] `iam.tf` — EC2 Role + Instance Profile + SSMManagedInstanceCore
- [ ] `alb.tf` — ALB + TG(Health:/health) + Listener(HTTP:80)
- [ ] `asg.tf` — Launch Template(AL2023, t3.micro, User Data) + ASG(1/3/2, 2AZ) + Target Tracking(CPU 70%)
- [ ] `rds.tf` — RDS MySQL(db.t3.micro, Single-AZ, 8.0) + DB Subnet Group

---

### Phase 2 — 보안 (Security)

**목표**: HTTPS 적용, 웹 공격 차단, DB 비밀번호 안전 관리, 네트워크/API 로그 수집

**서비스**: S3(로그), ACM, WAF, Secrets Manager, KMS, VPC Flow Logs, GuardDuty, NACL

**TODO**:
- [ ] `s3-logs.tf` — 로그 버킷(SSE-S3, 수명주기 90일, Flow Logs/ALB/CloudTrail 쓰기 정책)
- [ ] `acm.tf` — 인증서 요청 + DNS 검증
- [ ] `waf.tf` — Web ACL(CommonRuleSet, SQLi, KnownBadInputs, Rate Limit 2000/5min) + ALB 연결
- [ ] `secrets.tf` — KMS 키 + Secrets Manager(DB 비밀번호) + RDS 연결
- [ ] `iam.tf` 수정 — secretsmanager:GetSecretValue + KMS Decrypt 추가
- [ ] `flowlogs.tf` — VPC Flow Logs → S3
- [ ] `alb.tf` 수정 — Access Logs 활성화, HTTPS:443 Listener(ACM), HTTP→HTTPS 리다이렉트
- [ ] `guardduty.tf` — GuardDuty Detector 활성화

---

### Phase 3 — 안정성 (Reliability)

**목표**: DB 장애 시 자동 전환, 데이터 백업, 복구 가능 상태

**서비스**: RDS(Multi-AZ, 백업, 암호화)

**TODO**:
- [ ] `rds.tf` 수정 — multi_az=true, backup_retention_period=7, storage_encrypted=true(KMS), deletion_protection=true

---

### Phase 4 — 성능 효율성 (Performance Efficiency)

**목표**: 정적 콘텐츠 엣지 캐싱, DB 읽기 부하 분산, 응답 속도 향상

**서비스**: CloudFront, ElastiCache Redis, Route 53

**TODO**:
- [ ] `cloudfront.tf` — Distribution(Origin:ALB, HTTPS redirect, Cache Policy) + WAF 연결
- [ ] `elasticache.tf` — Redis Replication Group + Subnet Group(Priv-DB) + at_rest/in_transit 암호화
- [ ] `route53.tf` — Health Check (도메인 있을 경우)

---

### Phase 5 — 운영 우수성 (Operational Excellence)

**목표**: 이상 감지 → 자동 알림, API 감사, 설정 변경 추적, 통합 대시보드

**서비스**: SNS, CloudWatch(Agent+알람+대시보드), CloudTrail, AWS Config, SSM, Managed Grafana

**TODO**:
- [ ] `sns.tf` — Topic + 이메일 구독
- [ ] `iam.tf` 수정 — CloudWatchAgentServerPolicy 추가
- [ ] `cloudwatch.tf` — 알람(EC2 CPU>90%, ALB 5xx>10, RDS CPU>80% → SNS) + 대시보드 + Agent 설정
- [ ] `cloudtrail.tf` — Trail → S3(멀티리전, 관리 이벤트)
- [ ] `config.tf` — Config Recorder + Delivery Channel + 기본 규칙
- [ ] `ssm.tf` — Session Manager 로그→S3, Patch Manager(Baseline + Maintenance Window)
- [ ] `grafana.tf` — Workspace + IAM Role + 데이터 소스(CloudWatch, CloudTrail)

---

### Phase 6 — 비용 최적화 (Cost Optimization)

**목표**: 예산 초과 자동 알림, 스토리지 비용 절감

**서비스**: Budgets, S3 Intelligent-Tiering

**TODO**:
- [ ] `budgets.tf` — 월 예산 + 80%/100% 임계치 → SNS 알림
- [ ] `s3.tf` — 백업 버킷(Intelligent-Tiering, 180일 후 Glacier)

---

### Phase 7 — 지속 가능성 (Sustainability)

**목표**: 에너지 효율적 컴퓨팅 자원 사용

**서비스**: Graviton(t4g)

**TODO**:
- [ ] `asg.tf` 수정 — Launch Template 인스턴스 타입 t4g.micro + ARM AMI 변경
