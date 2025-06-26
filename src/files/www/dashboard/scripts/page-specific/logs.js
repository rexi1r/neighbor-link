const container = document.getElementById('log-content');
const title = document.getElementById('log-title');
const buttons = document.querySelectorAll('[data-type]');

function loadLogs(type){
    loading(true, 'Loading logs');
    const CMD=["file","exec",{"command":"dragon.sh","params":["monitor-log", type]}];
    async_ubus_call(CMD).then(res => {
        const html = highlightStatus(res[1].stdout || '').replace(/\n/g, '<br>');
        container.innerHTML = html;
        if (title) {
            const label = type.charAt(0).toUpperCase() + type.slice(1);
            title.textContent = `${label} Log`;
        }
        loading(false);
    });
}

buttons.forEach(btn => {
    btn.addEventListener('click', () => loadLogs(btn.dataset.type));
});

document.addEventListener('DOMContentLoaded', () => {
    loadLogs('starlink');
});

function highlightStatus(text){
    if(!text) return '';
    const sanitized = text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
    return sanitized
        .replace(/\x1b\[0;31m/g, '<span class="text-danger">')
        .replace(/\x1b\[0;32m/g, '<span class="text-success">')
        .replace(/\x1b\[0m/g, '</span>')
        .replace(/\bFAIL\b/g, '<span class="text-danger">FAIL</span>')
        .replace(/\bOK\b/g, '<span class="text-success">OK</span>');
}
