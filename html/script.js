let currentCategory = 'all';
let cachedPlayers = [];
let searchQuery = '';
let jobsSetup = false;
let jobColors = { 'default': '#a855f7' };
let shouldAnimate = true;

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'show') {
        const scoreboard = document.getElementById('scoreboard');
        if (scoreboard.classList.contains('hidden')) {
            shouldAnimate = true;
        }
        showScoreboard(data.data);
    } else if (data.action === 'hide') {
        hideScoreboard();
    }
});

function showScoreboard(data) {
    const scoreboard = document.getElementById('scoreboard');
    scoreboard.classList.remove('hidden');
    scoreboard.classList.remove('closing');


    if (!jobsSetup && data.jobsConfig) {
        setupJobs(data.jobsConfig, data.defaultJobColor);
        jobsSetup = true;
    }

    document.getElementById('serverName').textContent = data.serverName || "Test Server";
    document.getElementById('playersOnline').textContent = data.playersOnline;
    document.getElementById('maxPlayers').textContent = data.maxPlayers || 100;

    if (data.jobsConfig) {
        data.jobsConfig.forEach(job => {
            const countElem = document.getElementById(`count_${job.name}`);
            if (countElem) {
                countElem.textContent = data.jobCount[job.name] || 0;
            }
        });
    }

    cachedPlayers = data.players || [];
    updatePlayersTable();
}

function setupJobs(jobsConfig, defaultColor) {
    jobColors = { 'default': defaultColor || '#a855f7' };
    
    const jobStatsContainer = document.getElementById('jobStatsContainer');
    const filterTabsContainer = document.getElementById('filterTabsContainer');
    
    jobStatsContainer.innerHTML = '';
    filterTabsContainer.innerHTML = '<button class="tab-btn active" data-filter="all">All</button>';
    
    jobsConfig.forEach(job => {
        jobColors[job.name] = job.color;
        
        const card = document.createElement('div');
        card.className = `job-card ${job.name}`;
        card.style.borderLeft = `3px solid ${job.color}`;
        card.innerHTML = `
            <div class="job-icon">${job.icon}</div>
            <div class="job-info">
                <span class="job-label">${job.label}</span>
                <div class="job-count">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                        <circle cx="12" cy="7" r="4"></circle>
                    </svg>
                    <span id="count_${job.name}">0</span>
                </div>
            </div>
        `;
        jobStatsContainer.appendChild(card);
        
        const tab = document.createElement('button');
        tab.className = 'tab-btn';
        tab.setAttribute('data-filter', job.name);
        tab.textContent = job.label;
        filterTabsContainer.appendChild(tab);
    });

    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            currentCategory = btn.getAttribute('data-filter');
            shouldAnimate = true;
            updatePlayersTable();
        });
    });
}

function updatePlayersTable() {
    const grid = document.getElementById('playersGrid');
    grid.innerHTML = '';

    const players = cachedPlayers.filter(player => {
        const matchCategory = (currentCategory === 'all' || player.jobName === currentCategory);
        let matchSearch = true;
        if (searchQuery !== '') {
            matchSearch = player.name.toLowerCase().includes(searchQuery) ||
                          player.id.toString().includes(searchQuery);
        }
        return matchCategory && matchSearch;
    });

    players.forEach((player, index) => {
        const card = document.createElement('div');
        card.className = 'player-card';
        
        if (shouldAnimate) {
            card.style.animation = 'popIn 0.4s cubic-bezier(0.4, 0, 0.2, 1) forwards';
            card.style.animationDelay = `${index * 0.02}s`;
            card.style.opacity = '0';
        } else {
            card.style.opacity = '1';
            card.style.animation = 'none';
        }


        if (player.isSpecial) {
            card.classList.add('special-role');
            if (player.rank === 'Admin') card.classList.add('admin-role');
            else if (player.rank === 'Mod') card.classList.add('mod-role');
            else if (player.rank === 'Founder') card.classList.add('founder-role');
        }

        const jobColor = jobColors[player.jobName] || jobColors['default'];
        card.style.borderLeft = `4px solid ${jobColor}`;

        const pingInfo = getPingInfo(player.ping);

        card.innerHTML = `
            <div class="player-card-left">
                <span class="id-badge">${player.id}</span>
                <div class="avatar-wrapper">
                    <img src="${player.avatar || 'https://cdn.discordapp.com/embed/avatars/0.png'}" alt="Avatar" class="player-avatar">
                    ${player.isVip ? '<span class="vip-crown-overlay">👑</span>' : ''}
                </div>
                <div class="player-info-text">
                    <div class="name-row">
                        ${player.isVip ? '' : (player.roleIcon ? `<span class="player-icon">${player.roleIcon}</span>` : '')}
                        <span class="player-name-text ${player.isVip ? 'vip-text' : ''}">${escapeHtml(player.name)}</span>
                        ${player.isVip ? '<span class="vip-badge">VIP</span>' : ''}
                    </div>
                    <div class="details-row">
                        <span class="playtime-badge">${player.playtime || 0}h</span>
                    </div>
                </div>
            </div>
            
            <div class="player-card-right">
                <div class="job-info-right">
                    <span class="job-text" style="color: ${jobColor}">${player.job}</span>
                </div>
                <div class="ping-indicator ${pingInfo.class}">
                    ${pingInfo.bars}
                    <span class="ping-value">${player.ping}ms</span>
                </div>
            </div>
        `;

        grid.appendChild(card);
    });

    shouldAnimate = false;
}

function getPingInfo(ping) {
    let bars = '';
    let className = 'ping-good';

    if (ping < 50) {
        bars = '<div class="signal-bars"><div class="bar active"></div><div class="bar active"></div><div class="bar active"></div></div>';
        className = 'ping-good';
    } else if (ping < 100) {
        bars = '<div class="signal-bars"><div class="bar active"></div><div class="bar active"></div><div class="bar"></div></div>';
        className = 'ping-medium';
    } else {
        bars = '<div class="signal-bars"><div class="bar active"></div><div class="bar"></div><div class="bar"></div></div>';
        className = 'ping-high';
    }

    return {
        bars: bars,
        class: className
    };
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}

document.querySelector('.exit-btn').addEventListener('click', function () {
    closeScoreboard();
});

document.getElementById('searchInput').addEventListener('input', function(event) {
    searchQuery = event.target.value.toLowerCase().trim();
    shouldAnimate = true;
    updatePlayersTable();
});

document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape' || event.key === 'F10') {
        closeScoreboard();
    }
});

function closeScoreboard() {
    hideScoreboard();
    fetch(`https://${GetParentResourceName()}/closeScoreboard`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
}

function hideScoreboard() {
    const scoreboard = document.getElementById('scoreboard');
    if (!scoreboard.classList.contains('hidden') && !scoreboard.classList.contains('closing')) {
        scoreboard.classList.add('closing');
        setTimeout(() => {
            scoreboard.classList.add('hidden');
            scoreboard.classList.remove('closing');
        }, 300);
    }
}


