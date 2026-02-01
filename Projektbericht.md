# Praktikum ASP - Team 120- Abgabe Aufgabe 217

## LEHRSTUHL FÜR RECHNERARCHITEKTUR

## Wintersemester 2025/26

# Burning Ship-Fraktal

### Joel Chiu, Leif Nissen, Arthur Öttl

## 1. Problemstellung

Das Projekt soll ein Burning Ship-Fraktal ausgeben. Hierzu können vom Nutzer folgende Parameter eingegeben werden können:

- -V <*Zahl*> Implementierung
- -B <*Zahl*> Benchmark-Wiederholungen
- -s <*Realteil*>, <*Imaginärteil*> Startpunkt
- -d <*Zahl*>, <*Zahl*> Breite & Höhe
- -n <*Zahl*> Iterationen
- -r <*Floating Point Zahl*> Schrittweite
- -o <*Dateiname*> Ausgabedatei 
- -h Help Message

Eine Beispieleingabe wäre demnach: 

*./burning_ship -V 0 -o burning_ship.bmp -s -1.8,0.01 -d 1920,1080 -n 500 -r 0.0001*

## 2. Lösungsansätze

### Mathematische Grundlagen

Das Burning Ship-Fraktal basiert auf der zentralen Iterationsgleichung:

$$
z_{k+1} = (|Re(z_k)| + i|Im(z_k)|)^2 + c \quad (k \geq 0)
$$

Mit Startwert $z_0 = 0$. Der Parameter c entspricht den Pixelkoordinaten in der komplexen Ebene:

$$
c = c_x + i \cdot c_y
$$

Im Vergleich zur Mandelbrot-Iteration $z_{k+1} = z_k^2 + c$ ist das Burning Ship-Fraktal durch seine Betragsfunktionen charakteristisch asymmetrisch.

### Explizite Berechnung

Für die Implementierung in Assembly muss die komplexe Arithmetik zunächst in reelle Operationen aufgelöst werden.

Mit der Substitution $z_k = x_k + i \cdot y_k$ und $c = c_x + i \cdot c_y$ ergibt sich durch Expansion der binomischen Formel:

$$
(|x_k| + i|y_k|)^2 = |x_k|^2 + (i|y_k|)^2 + 2i|x_k||y_k| = x_k^2 - y_k^2 + 2i|x_k||y_k|
$$

Daraus ergeben sich die Update-Formeln für Real- und Imaginärteil:

$$
x_{k+1} = x_k^2 - y_k^2 + c_x
$$

$$
y_{k+1} = 2|x_k||y_k| + c_y
$$

### Escape-Kriterium & Färbung

Das Escape-Kriterium bestimmt, ob ein Punkt zum Fraktal gehört oder divergiert:

$$
|z_k| = \sqrt{x_k^2 + y_k^2} > 2
$$

Die Färbung basiert auf der Anzahl der Iterationen bis zur Divergenz:

- beschränkt nach n Iterationen: **schwarz**

- escaped vor n Iterationen: Farbe = Divergenzrate

### Vergleichsimplementierungen

Zur Analyse wurden vier Implementierungen erstellt:

| Version | Beschreibung                         | Parallelität                    |
| ------- | ------------------------------------ | ------------------------------- |
| V0      | SIMD Assembly (Hauptimplementierung) | 4-fach (Pixel), 3-fach (Farben) |
| V1      | SISD Assembly                        | Keine                           |
| V2      | C ohne Optimierung                   | Keine                           |
| V3      | C mit -O3                            | Compiler-abhängig               |

## 3. Optimierungen

### SIMD-Parallelisierung

- **Iteration**: Die Quadrierung und Addition erfolgt parallel für vier Pixel: 
  
  ```asm6502
  movups xmm13, xmm10  # zx²
  mulps xmm13, xmm13
  ```
  
  Für Bildbreiten, die nicht durch 4 teilbar sind, werden die letzten 1-3 Pixel einer Zeile mit der SISD-Variante berechnet.

- **Divergenz**: Der parallele Divergenz-Check erfolgt mittels: 
  
  ```asm5602
  cmpps xmm4, xmm7, 1  # zx² + zy² < 4
  ```

- **Färbung**: Die RGB-Werte werden parallel multipliziert:
  
  ```asm5602
  pmulld xmm13, [rip + blue]     # blue
  pmulld xmm10, [rip + green]    # green
  pmulld xmm12, [rip + red]      # red
  ```

## 4. Genauigkeit

Die Korrektheit bzw. Genauigkeit der Assembly-Implementierung wird durch einen Vergleich mit der C-Implementierung validiert. Hierzu vergleicht ein Python-Skript die generierten BMP-Dateien:

```python
import filecmp
is_same = filecmp.cmp('burning_ship_fractal_s.bmp', 'burning_ship_fractal_c.bmp')
```

Alle Tests bestätigen die Übereinstimmung zwischen Assembly und C-Referenz.

## 5. Performanzanalyse

Um die Performanz der Algorithmen zu testen, wurden mehrere Versuchsreihen mit der folgenden Frage durchgeführt: Wie schnell wird ein Burning Ship-Fraktal als .bmp-Datei in verschiedenen Implementierungen erstellt?

Alle Messversuche wurden auf einem Computer mit den folgenden technischen Daten ausgeführt: 

- CPU: Intel(R) Processor U300 (5 cores, 0.4–4.4 GHz)

- RAM: 16 GB DDR4

- SIMD: SSE4.2 supported

- OS: Ubuntu 25.04

- Compiler: GCC (Ubuntu 14.2.0-19ubuntu2) 14.2.0

- System connected to power

- Power mode set to 'Performance'

Die Zeitmessungen wurden im Rahmenprogramm mit der Funktion clock_gettime() und dem Argument CLOCK_MONOTONIC ausgeführt.

![benchmark-graph](https://hackmd.io/_uploads/rJ-avE3LWl.svg)

Der erste Graph zeigt einen Laufzeitvergleich aller Implementierungen auf logarithmischer Skala. Die SIMD-Assembly-Implementierung (orange) erzielt durchgehend die beste Performance.

![bar-comparison](https://hackmd.io/_uploads/rk4RDN3I-e.svg)

Aus dem gruppierten Balkenvergleich der Laufzeiten lässt sich ein konsistentes Verhältnis zwischen den Implementierungen über die verschiedenen Problemstellungen hinweg ablesen.

![relative-performance](https://hackmd.io/_uploads/H1vy_EhLZg.svg)

Im relativen Laufzeitvergleich dient der unoptimierte C-Code als Referenzgröße. Auffällig ist hierbei, dass die Assembler-Implementierung mit wachsender Problemgröße im Verhältnis schneller wird und die SIMD-Implementierung mit circa 12–15 % am schnellsten ist.

## 6. Zusammenfassung & Ausblick

Im Rahmen des Projekts wurde ein effizienter Renderer für das Burning Ship-Fraktal in Assembly entwickelt. Das in C geschriebene Rahmenprogramm nimmt Nutzereingaben entgegen, ruft den Assembly-Code auf und gibt eine generierte BMP-Datei aus. Die mathematischen Berechnungen sowie die Werte der auszugebenden Pixel werden in Assembly durchgeführt.

Für zukünftige Optimierungen würden sich folgende Ansätze anbieten:

- Mit der **Advanced Vector Extension (AVX)** [2] kann man statt der begrenzten SIMD-Register das Programm auf 256-Bit-Register (AVX2) oder 512-Bit-Register (AVX-512) nutzen. Dadurch entsteht eine potenzielle Verdopplung bzw. Vervierfachung des Operationsdurchsatzes.

- Durch das Einsetzen eines **Anti-Aliasing-Filters** [3] können Aliasing-Artefakte in der Ausgabedatei reduziert werden. Das sorgt dafür, dass die Randbereiche des Fraktals weicher aussehen.

- Eine Portierung auf **GPU-Computing** [1] kann massive Parallelisierung ermöglichen, was zu einem erheblichen Geschwindigkeitsgewinn führen kann.

## Arbeitsteilung

### Joel Chiu

- Entwicklung der SISD- und SIMD-Implementierung
- Entwicklung der C-Implementierung und des C-Rahmenprogramms
- Aufnehmen der Benchmarking-Werte

### Leif Nissen

- ursprüngliche Entwicklung des C-Rahmenprogramms

### Arthur Öttl

- Mitentwicklung des C-Rahmenprogramms (Stress-Tests)

- Präsentationsgestaltung

- Benchmarking

- Projektbericht

- Python-Skript zur Validierung

## Quellenverzeichnis

[1] NVIDIA Corporation, *CUDA C++ Programming Guide*, Version 12.0, 2024. Verfügbar unter: https://docs.nvidia.com/cuda/cuda-c-programming-guide/

[2] C. Lomont, "Introduction to Intel® Advanced Vector Extensions," Intel Corporation, 2011. Verfügbar unter: https://hpc.llnl.gov/sites/default/files/intelAVXintro.pdf

[3] J. W. Wooten and F. P. Brooks Jr., "Efficient Supersampling Antialiasing for High-Performance Architectures," Technical Report TR91-023, University of North Carolina at Chapel Hill, 1991. Verfügbar unter: https://www.cs.unc.edu/techreports/91-023.pdf
