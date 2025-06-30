const express = require('express');
const fs = require('fs').promises;
const path = require('path');
const app = express();
const PORT = 19119;

// File paths as variables
const userFilePath = '/etc/chisel/users.json';
const portFilePath = './assignedport.json';
const o_portFilePath = './o_assignedport.json';

const portRange=19120
const portCount=41

const o_portRange=52120
const o_portCount=41

// Simple queue to serialize file access
const requestQueue = [];
let processing = false;

app.get('/assign', (req, res) => {
    requestQueue.push({ req, res });
    processQueue();
});

async function processQueue() {
    if (processing || requestQueue.length === 0) return;
    const { req, res } = requestQueue.shift();
    processing = true;
    try {
        await handleAssign(req, res);
    } finally {
        processing = false;
        processQueue();
    }
}

async function handleAssign(req, res) {
    const token = req.query.token;
    if (!token) {
        res.json({ code: 0, port: null });
        return;
    }

    const users = JSON.parse(await fs.readFile(userFilePath, 'utf8'));
    const assignedPorts = JSON.parse(await fs.readFile(portFilePath, 'utf8'));
    const o_assignedPorts = JSON.parse(await fs.readFile(o_portFilePath, 'utf8'));

    // Reverse the token to get the password
    const password = token.split('').reverse().join('');
    users[`${token}:${password}`] = [""];

    // Write to user.json atomically
    await atomicWrite(userFilePath, JSON.stringify(users, null, 2));

    let port = assignedPorts[token];
    if (!port) {
        // Find a random port that's not already assigned
        const availablePorts = Array.from({ length: portCount }, (_, i) => i + portRange)
            .filter(p => !Object.values(assignedPorts).includes(p));

        if (availablePorts.length === 0) {
            return res.json({ code: -1, port: null });
        }

        port = availablePorts[Math.floor(Math.random() * availablePorts.length)];
        assignedPorts[token] = port;

        // Write to assignedport.json atomically
        await atomicWrite(portFilePath, JSON.stringify(assignedPorts, null, 2));
    }

    let o_port = o_assignedPorts[token];
    if (!o_port) {
        // Find a random port that's not already assigned
        const availablePorts = Array.from({ length: o_portCount }, (_, i) => i + o_portRange)
            .filter(p => !Object.values(o_assignedPorts).includes(p));

        if (availablePorts.length === 0) {
            return res.json({ code: -1, port: null, outlineport:null });
        }

        o_port = availablePorts[Math.floor(Math.random() * availablePorts.length)];
        o_assignedPorts[token] = o_port;

        // Write to assignedport.json atomically
        await atomicWrite(o_portFilePath, JSON.stringify(o_assignedPorts, null, 2));
    }

    res.json({ code: 1, port: port, outlineport: o_port });
}

async function startServer() {
    await checkAndCreateFile(userFilePath);
    await checkAndCreateFile(portFilePath);
    await checkAndCreateFile(o_portFilePath);
    app.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
    });
}



// Function to check and create file with empty JSON object
async function checkAndCreateFile(filePath) {
    try {
        await fs.access(filePath);
        console.log(`File already exists: ${filePath}`);
    } catch {
        const dir = path.dirname(filePath);
        await fs.mkdir(dir, { recursive: true });
        await fs.writeFile(filePath, '{}', 'utf8');
        console.log(`Created file: ${filePath}`);
    }
}

async function atomicWrite(filePath, data) {
    const tempPath = `${filePath}.tmp`;
    await fs.writeFile(tempPath, data);
    await fs.rename(tempPath, filePath);
}

startServer().catch(err => {
    console.error('Failed to start server:', err);
    process.exit(1);
});
