'use strict';

class ImageMapHighlighter {
    /**
     * @param {HTMLImageElement} element
     * @param {Object} options
     */
    constructor(element, options = {}) {
        this.element = element;
        this.options = Object.assign({}, this._getDefaultOptions(), options);
    }

    /**
     * Convert the image into a canvas that animates when you hover over parts
     * of it.
     */
    init() {
        // Get the HTML map element associated with the given image element.
        let map = this._getAssociatedMap(this.element);

        // Create a shiny new canvas with the same dimensions as the image.
        let canvas = this._createCanvasFor(this.element);

        // Create a container element and move the image element as well as
        // our shiny new canvas into it.
        let container = this._createContainerFor(this.element);
        this.element.parentNode.insertBefore(container, this.element);
        container.appendChild(this.element);
        container.insertBefore(canvas, this.element);

        if (this.options.alwaysOn) {
            for (var i = 0; i < map.areas.length; i++) {
                let area = map.areas[i];

                this._drawHighlightByArea(canvas, area);
            }
        } else {
            // Animate the canvas accordingly every time we hover over an image
            // mapping.
            map.addEventListener('mouseover', event => {
                this._clearHighlights(canvas);
                this._drawHighlightByArea(canvas, event.target);
            });

            // Clear the canvas when we hover off a mapping.
            map.addEventListener('mouseout', event => {
                this._clearHighlights(canvas);
            });
        }
    }

    _getDefaultOptions() {
        return {
            fill: true,
            fillColor: '000000',
            fillOpacity: 0.2,
            stroke: true,
            strokeColor: 'ff0000',
            strokeOpacity: 1,
            strokeWidth: 1,
            alwaysOn: false
        };
    }

    /**
     * Create and return a new HTML div element.
     *
     * @param {HTMLImageElement} element
     * @returns {HTMLDivElement}
     * @private
     */
    _createContainerFor(element) {
        let container = document.createElement('div');
        container.classList.add('map-container');
        container.style.backgroundImage = `url(${element.src})`;
        container.style.height = `${element.height}px`;
        container.style.width = `${element.width}px`;
        return container;
    }

    /**
     * Create and return a new HTML canvas element.
     *
     * @param {HTMLImageElement} element
     * @returns {HTMLCanvasElement}
     * @private
     */
    _createCanvasFor(element) {
        let canvas = document.createElement('canvas');
        canvas.height = element.height;
        canvas.width = element.width;
        return canvas;
    }

    /**
     * Return the HTML map element referenced by the given HTML image element.
     *
     * @param {HTMLImageElement} element
     * @returns {HTMLMapElement}
     * @private
     */
    _getAssociatedMap(element) {
        if (!element.useMap) {
            throw new Error('The "useMap" attribute for this image element has not been set.');
        }

        let map = document.querySelector(`map[name=${element.useMap.substr(1)}]`);
        if (map === null) {
            throw new Error(`The requested map "${element.useMap}" could not be found.`);
        }

        return map;
    }

    /**
     * Clear the canvas.
     *
     * @param {HTMLCanvasElement} canvas
     * @private
     */
    _clearHighlights(canvas) {
        let context = canvas.getContext('2d');
        context.clearRect(0, 0, canvas.width, canvas.height);
    }

    /**
     * Draw the map area co-ordinates onto the provided HTML canvas element.
     *
     * @param {HTMLCanvasElement} canvas
     * @param {HTMLAreaElement} area
     * @private
     */
    _drawHighlightByArea(canvas, area) {
        let coords = area.coords.split(',').map(coord => parseInt(coord));
        let shape = area.shape;

        this._drawHighlight(canvas, shape, coords);
    }

    /**
     * Draw a highlight onto the provided HTML canvas element.
     *
     * @param {HTMLCanvasElement} canvas
     * @param {String} shape
     * @param {Array} coords
     * @private
     */
    _drawHighlight(canvas, shape, coords) {
        let context = canvas.getContext('2d');

        context.beginPath();
        switch (shape) {
            case 'circle':
                context.arc(coords[0], coords[1], coords[2], 0, Math.PI * 2, false);
                break;
            case 'poly':
                context.moveTo(coords[0], coords[1]);
                for (let i = 2; i < coords.length; i += 2) {
                    context.lineTo(coords[i], coords[i + 1]);
                }
                break;
            case 'rect':
                context.rect(coords[0], coords[1], coords[2] - coords[0], coords[3] - coords[1]);
                break;
            default:
        }
        context.closePath();

        if (this.options.fill) {
            context.fillStyle = this.css3Colour(this.options.fillColor, this.options.fillOpacity);
            context.fill();
        }

        if (this.options.stroke) {
            context.strokeStyle = this.css3Colour(this.options.strokeColor, this.options.strokeOpacity);
            context.lineWidth = this.options.strokeWidth;
        }

        context.stroke();
    }

    /**
     * @param {String} hex
     * @returns {Number}
     */
    hexToDecimal(hex) {
        return Math.max(0, Math.min(parseInt(hex, 16), 255));
    }

    /**
     * @param {String} colour
     * @param {Number} opacity
     * @returns {String}
     */
    css3Colour(colour, opacity) {
        let r = +this.hexToDecimal(colour.substr(0, 2));
        let g = +this.hexToDecimal(colour.substr(2, 2));
        let b = +this.hexToDecimal(colour.substr(4, 2));

        return `rgba(${r}, ${g}, ${b}, ${opacity})`;
    }
}

module.exports = ImageMapHighlighter;
