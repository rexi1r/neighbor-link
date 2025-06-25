const container = document.getElementById('log-content');
const buttons = document.querySelectorAll('[data-type]');

function loadLogs(type){
    loading(true, 'Loading logs');
    const CMD=["file","exec",{"command":"dragon.sh","params":["monitor-log", type]}];
    async_ubus_call(CMD).then(res => {
        container.textContent = res[1].stdout || '';
        loading(false);
    });
}

buttons.forEach(btn => {
    btn.addEventListener('click', () => loadLogs(btn.dataset.type));
});

document.addEventListener('DOMContentLoaded', () => {
    loadLogs('starlink');
});
