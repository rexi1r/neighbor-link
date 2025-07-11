const container = document.getElementById('log-content');
const title = document.getElementById('log-title');
const buttons = document.querySelectorAll('[data-type]');
const logSize = document.getElementById('log-size');
const clearBtn = document.getElementById('clear-log');
let currentType = 'starlink';

function formatBytes(bytes){
    if(!bytes) return '0 B';
    const sizes=['B','KB','MB','GB'];
    const i=Math.floor(Math.log(bytes)/Math.log(1024));
    return (bytes/Math.pow(1024,i)).toFixed(1)+' '+sizes[i];
}

function updateLogSize(type){
    const CMD=["file","exec",{"command":"dragon.sh","params":["log-size", type]}];
    return async_ubus_call(CMD).then(res=>{
        const bytes=parseInt(res[1].stdout||'0');
        if(logSize) logSize.textContent=formatBytes(bytes);
    });
}

function loadLogs(type){
    currentType = type;
    loading(true, 'Loading logs');
    const CMD=["file","exec",{"command":"dragon.sh","params":["monitor-log", type]}];
    async_ubus_call(CMD).then(res => {
        const html = highlightStatus(res[1].stdout || '').replace(/\n/g, '<br>');
        container.innerHTML = html;
        if (title) {
            const label = type.charAt(0).toUpperCase() + type.slice(1);
            title.textContent = `${label} Log`;
        }
        updateLogSize(type);
        loading(false);
    });
}

buttons.forEach(btn => {
    btn.addEventListener('click', () => loadLogs(btn.dataset.type));
});

if(clearBtn){
    clearBtn.addEventListener('click', () => {
        if(confirm('Clear current log?')){
            const CMD=["file","exec",{"command":"dragon.sh","params":["clear-log", currentType]}];
            async_ubus_call(CMD).then(()=>loadLogs(currentType));
        }
    });
}

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
