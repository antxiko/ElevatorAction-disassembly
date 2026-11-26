# The game

A spy comes in over the roof of a thirty-storey building and has to reach the car waiting for him in the basement.
On the way there are red doors with documents: if he gets to the bottom without opening them all, a lift takes him
back up for them. Enemy agents come out of the blue doors; they shoot, jump and duck.

## The controls

| key | what it does | where it is read |
|---|---|---|
| cursor keys or joystick | walk, duck, move the lift up or down | `agente_direccion`, 0x518A |
| `x` or the second button | jump | `agente_mando`, 0x50F2 |
| `z` or the first button | shoot (one bullet per press, three at most at once) | `agente_dispara`, 0x531E |
| space bar | start, on the title | `titulo_lee_disparo`, 0x4B1E |

The `x` and `z` keys are read straight from the keyboard matrix with SNSMAT (table 0x4917: row 5, bits 5 and 7).

## A round

In round 1 the agent arrives along a cable stretched to the roof (`entrada_cable`, 0x716C); in the others he is
already up there. He walks to the roof lift and from there the building is covered with:

- **Lifts.** Inside the car, up and down move it; he can also ride standing on its roof, and a lift coming down
  crushes whoever is underneath.
- **Escalators.** Only on floors 20 to 16. Pushing up or down at the foot of each flight takes him up or down in
  seven steps.
- **Doors.** In front of a door and facing it, the agent goes in. In a red one he picks up the documents (500
  points) and the door turns blue; in a blue one he hides until the controls move or 255 frames go by.

Reaching the basement with every red door opened, the agent gets into the car and drives off: **a bonus of 1000
points per round**, up to 9,000 from the ninth on. The next round is the same building with other colours and other
red doors.

## The points

| what | points | where |
|---|---:|---|
| an enemy shot | 100 (150 in the dark, or with the view between rows 0x5E and 0x7A of the map) | 0x6E08 |
| an enemy kicked in a jump | 150 (200 in the same cases) | 0x6B6B |
| an enemy under the falling lamp, or crushed by a lift | 300 | 0x6B16, 0x6378 |
| the documents behind a red door | 500 | 0x5087 |
| the round bonus | 1000 per round, 9000 at most | 0x416B |

The extra life comes only once, at 10,000 (`bucle_juego`, 0x4065). The game starts with two spare lives.

## The ways to die

Three, each with its own pose (`agente_muere`, 0x4EF9): falling down a lift shaft, getting shot and having a lift come
down on him. On losing a life the agent goes back a few floors up, on a row that is a multiple of six
(`vida_perdida`, 0x419B). With no lives left, GAME OVER, and the high score is kept if beaten.

## The lamp

A bullet that reaches a ceiling lamp breaks it: the lamp falls in four steps and kills the enemy it lands on, and ten
frames later the building goes dark for 240 frames with another set of colours (`luces_cuadro`, 0x7D67).
