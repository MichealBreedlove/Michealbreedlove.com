/**
 * AI Cluster Interactive Diagram
 * Pure vanilla JS — zero dependencies
 */

(function () {
    'use strict';

    const ICONS = {
        gpu: '🖥️',
        server: '🗄️',
        compute: '⚡',
        rack: '🏗️'
    };

    // Node positions (percentage-based for responsiveness)
    const POSITIONS = {
        jasper: { x: 50, y: 15 },
        nova:   { x: 15, y: 55 },
        mira:   { x: 85, y: 55 },
        orin:   { x: 50, y: 85 }
    };

    const MOBILE_POSITIONS = {
        jasper: { x: 50, y: 10 },
        nova:   { x: 25, y: 38 },
        mira:   { x: 75, y: 38 },
        orin:   { x: 50, y: 68 }
    };

    let data = null;
    let activeNode = null;

    async function init() {
        try {
            const resp = await fetch('/assets/cluster/cluster-data.json');
            data = await resp.json();
            render();
            window.addEventListener('resize', debounce(updateConnections, 150));
        } catch (e) {
            console.error('Cluster diagram: failed to load data', e);
        }
    }

    function render() {
        const diagram = document.getElementById('cluster-diagram');
        const svg = document.getElementById('cluster-svg');
        if (!diagram || !svg) return;

        // Render nodes
        data.nodes.forEach(node => {
            const card = createNodeCard(node);
            diagram.appendChild(card);
        });

        // Render connections
        renderConnections(svg);

        // Render stats
        renderStats();
    }

    function createNodeCard(node) {
        const pos = getPositions()[node.id];
        const card = document.createElement('div');
        card.className = 'node-card';
        card.id = `node-${node.id}`;
        card.tabIndex = 0;
        card.setAttribute('role', 'button');
        card.setAttribute('aria-label', `${node.name}: ${node.role}. Click for details.`);
        card.style.cssText = `
            left: ${pos.x}%;
            top: ${pos.y}%;
            transform: translate(-50%, -50%);
            --node-color: ${node.color};
            --node-color-rgb: ${hexToRgb(node.color)};
        `;

        card.innerHTML = `
            <div class="node-icon" style="background: linear-gradient(135deg, ${node.color}, ${node.color}88);">
                ${ICONS[node.icon] || '💻'}
            </div>
            <h3>${node.name}</h3>
            <p class="node-role">${node.role}</p>
            <div class="node-specs">
                <span>${node.cpu.split('(')[0].trim()}</span>
                <span>${node.ram} ${node.gpu !== 'Integrated' && node.gpu !== 'None' ? '• ' + node.gpu.split(' ').slice(-2).join(' ') : ''}</span>
            </div>
            <div class="node-tooltip">
                <strong>${node.name}</strong> — ${node.os}<br>
                <strong>CPU:</strong> ${node.cpu}<br>
                <strong>RAM:</strong> ${node.ram}<br>
                <strong>Network:</strong> ${node.network}<br>
                <strong>Services:</strong> ${node.services.length} running
            </div>
        `;

        card.addEventListener('click', () => toggleDetail(node));
        card.addEventListener('keydown', e => {
            if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                toggleDetail(node);
            }
        });

        // Highlight connections on hover
        card.addEventListener('mouseenter', () => highlightConnections(node.id, true));
        card.addEventListener('mouseleave', () => highlightConnections(node.id, false));

        return card;
    }

    function renderConnections(svg) {
        svg.innerHTML = '';
        const diagram = document.getElementById('cluster-diagram');
        const rect = diagram.getBoundingClientRect();

        data.connections.forEach((conn, i) => {
            const fromPos = getPositions()[conn.from];
            const toPos = getPositions()[conn.to];

            const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
            line.setAttribute('x1', `${fromPos.x}%`);
            line.setAttribute('y1', `${fromPos.y}%`);
            line.setAttribute('x2', `${toPos.x}%`);
            line.setAttribute('y2', `${toPos.y}%`);
            line.classList.add(`conn-${conn.type}`);
            line.dataset.from = conn.from;
            line.dataset.to = conn.to;
            line.id = `conn-${i}`;

            // Animate dashes
            if (conn.type === 'control') {
                line.style.animation = `dashMove ${3 + i * 0.5}s linear infinite`;
            }

            svg.appendChild(line);
        });

        // Add dash animation keyframes if not present
        if (!document.getElementById('dash-anim-style')) {
            const style = document.createElement('style');
            style.id = 'dash-anim-style';
            style.textContent = `
                @keyframes dashMove {
                    to { stroke-dashoffset: -24; }
                }
            `;
            document.head.appendChild(style);
        }
    }

    function updateConnections() {
        const svg = document.getElementById('cluster-svg');
        if (svg && data) {
            renderConnections(svg);
            // Reposition nodes
            data.nodes.forEach(node => {
                const card = document.getElementById(`node-${node.id}`);
                if (card) {
                    const pos = getPositions()[node.id];
                    card.style.left = `${pos.x}%`;
                    card.style.top = `${pos.y}%`;
                }
            });
        }
    }

    function highlightConnections(nodeId, on) {
        const svg = document.getElementById('cluster-svg');
        if (!svg) return;
        svg.querySelectorAll('line').forEach(line => {
            if (line.dataset.from === nodeId || line.dataset.to === nodeId) {
                line.classList.toggle('highlight', on);
            }
        });
    }

    function toggleDetail(node) {
        const panel = document.getElementById('detail-panel');
        if (!panel) return;

        // If clicking same node, close
        if (activeNode === node.id) {
            panel.classList.remove('visible');
            document.getElementById(`node-${node.id}`).classList.remove('active');
            activeNode = null;
            return;
        }

        // Deactivate previous
        if (activeNode) {
            const prev = document.getElementById(`node-${activeNode}`);
            if (prev) prev.classList.remove('active');
        }

        activeNode = node.id;
        document.getElementById(`node-${node.id}`).classList.add('active');

        panel.style.setProperty('--node-color', node.color);
        panel.style.setProperty('--node-color-rgb', hexToRgb(node.color));

        panel.innerHTML = `
            <div class="detail-header">
                <div class="detail-icon" style="background: linear-gradient(135deg, ${node.color}, ${node.color}88);">
                    ${ICONS[node.icon] || '💻'}
                </div>
                <div>
                    <h3>${node.name}</h3>
                    <p class="detail-role">${node.role} • ${node.os}</p>
                </div>
                <button class="detail-close" aria-label="Close details" onclick="document.getElementById('detail-panel').classList.remove('visible'); document.getElementById('node-${node.id}').classList.remove('active');">✕</button>
            </div>
            <div class="detail-grid">
                <div class="detail-block">
                    <h4>Hardware</h4>
                    <ul>
                        <li>${node.cpu}</li>
                        <li>${node.ram}</li>
                        <li>GPU: ${node.gpu}</li>
                        <li>Network: ${node.network}</li>
                    </ul>
                </div>
                <div class="detail-block">
                    <h4>Services</h4>
                    <ul>
                        ${node.services.map(s => `<li>${s}</li>`).join('')}
                    </ul>
                </div>
                <div class="detail-block">
                    <h4>Responsibilities</h4>
                    <p>${node.responsibilities}</p>
                </div>
                <div class="detail-block">
                    <h4>Storage Role</h4>
                    <p>${node.storage_role}</p>
                </div>
                <div class="detail-block detail-why">
                    <h4>💡 Why This Matters (for recruiters)</h4>
                    <p>${node.why_it_matters}</p>
                </div>
            </div>
        `;

        panel.classList.add('visible');
        panel.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    function renderStats() {
        const container = document.getElementById('cluster-stats');
        if (!container || !data.stats) return;

        const stats = [
            { label: 'Compute', value: data.stats.total_cores },
            { label: 'Memory', value: data.stats.total_ram },
            { label: 'GPU', value: data.stats.gpu_vram },
            { label: 'Automations', value: `${data.stats.automation_priorities} priorities` },
            { label: 'Tests', value: `${data.stats.tests_passing} passing` }
        ];

        container.innerHTML = stats.map(s =>
            `<div class="stat-pill"><strong>${s.value}</strong> ${s.label}</div>`
        ).join('');
    }

    function getPositions() {
        return window.innerWidth <= 768 ? MOBILE_POSITIONS : POSITIONS;
    }

    function hexToRgb(hex) {
        const r = parseInt(hex.slice(1, 3), 16);
        const g = parseInt(hex.slice(3, 5), 16);
        const b = parseInt(hex.slice(5, 7), 16);
        return `${r},${g},${b}`;
    }

    function debounce(fn, ms) {
        let t;
        return function (...args) {
            clearTimeout(t);
            t = setTimeout(() => fn.apply(this, args), ms);
        };
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
