import {
  LngLatBounds,
  Map as MapLibre,
  Marker,
  NavigationControl,
  type MapMouseEvent,
  type StyleSpecification,
} from 'maplibre-gl';
import { useEffect, useRef } from 'react';

const TILE_URL: string =
  (import.meta.env['VITE_MAP_TILE_URL'] as string | undefined) ??
  'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const PUNE: [number, number] = [73.8567, 18.5204];

const STYLE: StyleSpecification = {
  version: 8,
  sources: {
    osm: {
      type: 'raster',
      tiles: [TILE_URL],
      tileSize: 256,
      attribution: '© OpenStreetMap contributors',
      maxzoom: 19,
    },
  },
  layers: [{ id: 'osm', type: 'raster', source: 'osm' }],
};

export interface LatLng {
  lat: number;
  lng: number;
}

function pin(color: string, label: string): HTMLElement {
  const el = document.createElement('div');
  el.setAttribute('aria-label', label);
  el.title = label;
  el.style.cssText = `width:14px;height:14px;border-radius:9999px;background:${color};border:2px solid #fff;box-shadow:0 1px 3px rgba(0,0,0,.4)`;
  return el;
}

/** The trip's GPS route (cleaned by the API) with pickup/drop pins. */
export function RouteMap({
  points,
  from,
  to,
}: {
  points: LatLng[];
  from: LatLng | null;
  to: LatLng | null;
}) {
  const container = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!container.current) return;
    const map = new MapLibre({
      container: container.current,
      style: STYLE,
      center: PUNE,
      zoom: 9,
      attributionControl: { compact: true },
    });
    map.addControl(new NavigationControl({ showCompass: false }), 'top-right');
    map.on('load', () => {
      if (points.length > 1) {
        map.addSource('route', {
          type: 'geojson',
          data: {
            type: 'Feature',
            properties: {},
            geometry: { type: 'LineString', coordinates: points.map((p) => [p.lng, p.lat]) },
          },
        });
        map.addLayer({
          id: 'route',
          type: 'line',
          source: 'route',
          paint: { 'line-color': '#2563eb', 'line-width': 3 },
          layout: { 'line-join': 'round', 'line-cap': 'round' },
        });
      }
      const all = [...points, ...(from ? [from] : []), ...(to ? [to] : [])];
      if (from)
        new Marker({ element: pin('#0ca30c', 'Pickup') })
          .setLngLat([from.lng, from.lat])
          .addTo(map);
      if (to)
        new Marker({ element: pin('#d03b3b', 'Drop') }).setLngLat([to.lng, to.lat]).addTo(map);
      const first = all[0];
      if (first) {
        const bounds = all.reduce(
          (b, p) => b.extend([p.lng, p.lat]),
          new LngLatBounds([first.lng, first.lat], [first.lng, first.lat]),
        );
        map.fitBounds(bounds, { padding: 40, maxZoom: 14, duration: 0 });
      }
    });
    return () => {
      map.remove();
    };
  }, [points, from, to]);
  return (
    <div
      ref={container}
      className="h-80 w-full overflow-hidden rounded-md border border-slate-200"
      role="img"
      aria-label="Map of the trip route"
    />
  );
}

/** Click the map to drop (or move) a pin. */
export function PointPicker({
  value,
  onChange,
  label,
}: {
  value: LatLng | null;
  onChange: (point: LatLng) => void;
  label: string;
}) {
  const container = useRef<HTMLDivElement>(null);
  const marker = useRef<Marker | null>(null);
  const map = useRef<MapLibre | null>(null);
  const onChangeRef = useRef(onChange);
  useEffect(() => {
    onChangeRef.current = onChange;
  }, [onChange]);

  useEffect(() => {
    if (!container.current) return;
    const instance = new MapLibre({
      container: container.current,
      style: STYLE,
      center: PUNE,
      zoom: 10,
      attributionControl: { compact: true },
    });
    instance.addControl(new NavigationControl({ showCompass: false }), 'top-right');
    instance.on('click', (e: MapMouseEvent) => {
      onChangeRef.current({
        lat: Number(e.lngLat.lat.toFixed(6)),
        lng: Number(e.lngLat.lng.toFixed(6)),
      });
    });
    map.current = instance;
    return () => {
      instance.remove();
      map.current = null;
      marker.current = null;
    };
  }, []);

  useEffect(() => {
    if (!map.current || !value) return;
    marker.current ??= new Marker({ element: pin('#2563eb', label) }).addTo(map.current);
    marker.current.setLngLat([value.lng, value.lat]);
  }, [value, label]);

  return (
    <div>
      <div
        ref={container}
        className="h-48 w-full overflow-hidden rounded-md border border-slate-200"
        role="application"
        aria-label={`${label}: click to place a pin`}
      />
      <p className="mt-1 text-xs text-slate-500">
        {value
          ? `${value.lat.toFixed(5)}, ${value.lng.toFixed(5)}`
          : 'Optional: click the map to pin the exact spot.'}
      </p>
    </div>
  );
}
