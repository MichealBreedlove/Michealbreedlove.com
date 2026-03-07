# LinkedIn Profile Content — Micheal Breedlove

---

## 1. LinkedIn Headline

```
Infrastructure Engineer | Reliability Engineering | Distributed Systems | Automation & Platform Operations
```

---

## 2. LinkedIn About Section

I design and operate infrastructure with an emphasis on automation, resilience, and operational discipline.

My current focus is a distributed AI cluster orchestration platform — a self-healing control plane that coordinates worker nodes, manages shared operational knowledge, and automates reliability workflows across a multi-node homelab environment. The system uses adaptive routing to assign tasks based on node health and observed performance, maintains a shared Markdown knowledge corpus for operational memory, and validates its own recovery capability through recurring disaster recovery drills.

Before infrastructure engineering, I spent a decade in operations-intensive environments: military intelligence (35N SIGINT, prior TS/SCI), Michelin-starred kitchens, and e-commerce operations management. Each of those roles taught me something about systems under pressure — how to make decisions with incomplete information, how to build processes that survive personnel turnover, and how to operate reliably when failure isn't optional.

I approach infrastructure the same way: design for failure, automate recovery, observe everything, and document decisions. The systems I build are meant to heal themselves, route work intelligently, and produce clear operational records — the same principles that matter at production scale.

Currently pursuing a B.S. in Cybersecurity & Information Assurance at WGU. Open to Infrastructure Engineer, SRE, Platform Engineer, and DevSecOps roles.

---

## 3. Featured Project Description

### AI Cluster Orchestration Platform

A self-healing distributed control plane designed to coordinate worker nodes, maintain shared operational knowledge, and automate infrastructure reliability workflows across a 4-node homelab cluster.

**Architecture:**
The platform is organized into five architectural planes — control, compute, knowledge, reliability, and observability — each with clear responsibilities and well-defined interfaces. The coordinator runs a continuous orchestration loop: check node health, dispatch queued jobs to the best available node, ingest completed results, and update cluster status.

**Orchestration:**
An adaptive routing engine scores task assignments against candidate nodes using a blend of static role fitness, historical success rate, average execution time, and recency of last assignment. A durable file-based job queue on shared storage handles dispatch, tracking, retry logic, and stale-job detection without external database dependencies.

**Reliability:**
Runtime watchdogs detect service degradation, quarantine bad state, and restore from verified backups. A portable recovery bundle packages the entire orchestrator for rapid rebuilds. Monthly disaster recovery drills validate the bundle in a sandboxed environment without touching live systems. Storage is backed by ZFS with automated snapshot policies at three retention tiers.

**Knowledge:**
A NAS-backed Markdown corpus serves as shared operational memory. Each node contributes daily observations; the coordinator curates these into long-term knowledge documents through an automated nightly curation cycle. Each node maintains a local semantic index for fast retrieval — shared knowledge stays in plain text, not shared databases.

**Autonomous Operations:**
A rule engine evaluates cluster health signals and creates maintenance or remediation tasks automatically. Safe operations execute without intervention. Risky actions are routed to an approval queue for human review. Cooldown tracking prevents duplicate task creation.

**Links:**
- Architecture: michealbreedlove.com/ai-cluster.html
- Live Status: michealbreedlove.com/status.html
- Source Code: github.com/MichealBreedlove/Lab

---

## 4. Skills List (Prioritized)

1. Infrastructure Automation
2. Reliability Engineering
3. Distributed Systems
4. Linux Systems Administration
5. Automation Scripting (Python, Bash, PowerShell)
6. Observability & Monitoring
7. Disaster Recovery Engineering
8. Platform Operations
9. Configuration Management (Ansible)
10. Network Security
11. Virtualization (Proxmox, KVM)
12. Storage Engineering (ZFS, NFS, TrueNAS)
13. CI/CD & GitOps
14. Incident Response
15. Technical Documentation

---

## 5. LinkedIn Featured Items

Recommended items for LinkedIn "Featured" section:

1. **Platform Architecture** — michealbreedlove.com/ai-cluster.html
   Caption: "AI Cluster Orchestration Platform — distributed control plane with adaptive routing, shared memory, and self-healing infrastructure."

2. **Live Infrastructure Status** — michealbreedlove.com/status.html
   Caption: "Live cluster dashboard with node health, queue activity, and orchestration status."

3. **GitHub Lab Repository** — github.com/MichealBreedlove/Lab
   Caption: "Open-source infrastructure code, automation, and documentation for the AI cluster platform."

4. **Portfolio Homepage** — michealbreedlove.com
   Caption: "Infrastructure engineering portfolio — distributed systems, reliability, automation, and recovery-first design."
