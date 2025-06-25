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
    resElem.textContent = result.trim();
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
