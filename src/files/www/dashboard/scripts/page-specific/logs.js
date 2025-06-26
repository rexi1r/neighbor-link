const container = document.getElementById('log-content');
const title = document.getElementById('log-title');
const buttons = document.querySelectorAll('[data-type]');

function loadLogs(type){
    loading(true, 'Loading logs');
    const CMD=["file","exec",{"command":"dragon.sh","params":["monitor-log", type]}];
    async_ubus_call(CMD).then(res => {
        container.textContent = res[1].stdout || '';
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
