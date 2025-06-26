const starHost = document.getElementById('starlink-host');
const starBtn = document.getElementById('starlink-check');
const starRes = document.getElementById('starlink-result');

const iranHost = document.getElementById('iran-host');
const iranBtn = document.getElementById('iran-check');
const iranRes = document.getElementById('iran-result');

const vpnBtn = document.getElementById('vpn-check');
const vpnRes = document.getElementById('vpn-result');

const cityBtn = document.getElementById('city-check');
const cityRes = document.getElementById('city-result');

async function check(link, host, resElem){
    loading(true, 'Checking...');
    let cmd = 'check-link ' + link;
    if(host){
        cmd += ' ' + host;
    }
    const result = await async_lua_call('dragon.sh', cmd);
    resElem.innerHTML = highlightStatus(result.trim());
    loading(false);
}

starBtn.addEventListener('click', ()=>{
    check('starlink', starHost.value || '8.8.8.8', starRes);
});

iranBtn.addEventListener('click', ()=>{
    check('iran', iranHost.value || '5.52.0.1', iranRes);
});

vpnBtn.addEventListener('click', ()=>{
    check('vpn', '', vpnRes);
});

cityBtn.addEventListener('click', ()=>{
    check('citylink', '', cityRes);
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
