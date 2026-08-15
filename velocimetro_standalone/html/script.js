const container = document.getElementById('speedometer-container');
const speedValue = document.getElementById('speed-value');
const gearValue = document.getElementById('gear-value');
const fuelProgress = document.getElementById('fuel-progress');
const fuelText = document.getElementById('fuel-text');

const iconLights = document.getElementById('icon-lights');
const iconDoors = document.getElementById('icon-doors');
const iconEngine = document.getElementById('icon-engine');

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === "toggle") {
        if (data.show) {
            container.classList.remove('hidden');
        } else {
            container.classList.add('hidden');
        }
    }

    if (data.action === "update") {
        // Velocidade
        speedValue.innerText = data.speed.toString().padStart(3, '0');

        // Marcha
        gearValue.innerText = data.gear;

        // Combustível
        if (data.isBicycle) {
            fuelProgress.style.width = '0%';
            fuelText.innerText = '-';
        } else {
            let fuelPercent = (data.fuel / data.maxFuel) * 100;
            if (fuelPercent < 0) fuelPercent = 0;
            if (fuelPercent > 100) fuelPercent = 100;

            fuelProgress.style.width = fuelPercent + '%';
            fuelText.innerText = Math.round(fuelPercent) + '%';

            // Muda cor se estiver na reserva
            if (fuelPercent < 20) {
                fuelProgress.style.background = 'linear-gradient(90deg, #ff4757, #ff6b81)';
            } else {
                fuelProgress.style.background = 'linear-gradient(90deg, #ffa502, #ff7f50)';
            }
        }

        // Ícones de Status
        if (data.lights) iconLights.classList.add('active');
        else iconLights.classList.remove('active');

        if (data.doors) iconDoors.classList.add('active');
        else iconDoors.classList.remove('active');

        if (data.engine) iconEngine.classList.add('active');
        else iconEngine.classList.remove('active');
    }
});
