const rl = @import("raylib");

const Scorer = struct {
    player: i32 = 0,
    ai: i32 = 0,

    pub fn draw(self: *const Scorer) void {
        const playerScore = rl.textFormat("%d", .{self.player});
        const aiScore = rl.textFormat("%d", .{self.ai});

        rl.drawText(aiScore, @divTrunc(rl.getScreenWidth(), 2) + 20, 20, 20, rl.Color.white);
        rl.drawText(playerScore, @divTrunc(rl.getScreenWidth(), 2) - 40, 20, 20, rl.Color.white);
    }

    pub fn update(self: *Scorer, ball: *const Ball) void {
        if (ball.x - @as(i32, @intFromFloat(ball.radius)) <= 0) {
            self.ai += 1;
        }

        if (ball.x + @as(i32, @intFromFloat(ball.radius)) >= rl.getScreenWidth()) {
            self.player += 1;
        }
    }
};

const Ball = struct {
    x: i32,
    y: i32,
    radius: f32 = 10,
    speed_x: i32 = 7,
    speed_y: i32 = 7,
    color: rl.Color = rl.Color.white,

    pub fn draw(self: *const Ball) void {
        rl.drawCircle(self.x, self.y, self.radius, self.color);
    }

    pub fn update(self: *Ball) void {
        self.x += self.speed_x;
        self.y += self.speed_y;

        if (self.x + @as(i32, @intFromFloat(self.radius)) >= rl.getScreenWidth() or self.x - @as(i32, @intFromFloat(self.radius)) <= 0) {
            self.speed_x *= -1;
        }

        if (self.y + @as(i32, @intFromFloat(self.radius)) >= rl.getScreenHeight() or self.y - @as(i32, @intFromFloat(self.radius)) <= 0) {
            self.speed_y *= -1;
        }
    }
};

const Paddle = struct {
    x: i32,
    y: i32,
    height: i32 = 120,
    width: i32 = 25,
    speed: i32 = 5,
    color: rl.Color = rl.Color.white,

    pub fn draw(self: *const Paddle) void {
        rl.drawRectangle(self.x, self.y, self.width, self.height, self.color);
    }

    pub fn update(self: *Paddle) void {
        if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
            self.y -= self.speed;
        }

        if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
            self.y += self.speed;
        }

        boundaryCheck(self);
    }

    fn boundaryCheck(self: *Paddle) void {
        if (self.y <= 0) {
            self.y = 0;
        }

        if (self.y + self.height >= rl.getScreenHeight()) {
            self.y = rl.getScreenHeight() - self.height;
        }
    }
};

const AIPaddle = struct {
    base: Paddle,

    pub fn update(self: *AIPaddle, ball: *const Ball) void {
        if (ball.y < self.base.y + @divTrunc(self.base.height, 2)) {
            self.base.y -= self.base.speed;
        }

        if (ball.y > self.base.y + @divTrunc(self.base.height, 2)) {
            self.base.y += self.base.speed;
        }

        self.base.boundaryCheck();
    }

    pub fn draw(self: *const AIPaddle) void {
        self.base.draw();
    }
};

pub fn main() !void {
    const screenWidth = 1280;
    const screenHeight = 720;

    rl.initWindow(screenWidth, screenHeight, "Pong");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var ball = Ball{
        .x = @divTrunc(rl.getScreenWidth(), 2),
        .y = @divTrunc(rl.getScreenHeight(), 2),
    };

    var player = Paddle{
        .x = rl.getScreenWidth() - 10 - 25,
        .y = @divTrunc(rl.getScreenHeight(), 2) - 60,
    };

    var ai = AIPaddle{
        .base = Paddle{
            .x = 10,
            .y = @divTrunc(rl.getScreenHeight(), 2) - 60,
        },
    };

    var scorer = Scorer{};

    while (!rl.windowShouldClose()) {
        if (rl.checkCollisionCircleRec(.{ .x = @as(f32, @floatFromInt(ball.x)), .y = @as(f32, @floatFromInt(ball.y)) }, ball.radius, rl.Rectangle{
            .x = @as(f32, @floatFromInt(player.x)),
            .y = @as(f32, @floatFromInt(player.y)),
            .width = @as(f32, @floatFromInt(player.width)),
            .height = @as(f32, @floatFromInt(player.height)),
        })) {
            ball.speed_x *= -1;
        }

        if (rl.checkCollisionCircleRec(.{ .x = @as(f32, @floatFromInt(ball.x)), .y = @as(f32, @floatFromInt(ball.y)) }, ball.radius, rl.Rectangle{
            .x = @as(f32, @floatFromInt(ai.base.x)),
            .y = @as(f32, @floatFromInt(ai.base.y)),
            .width = @as(f32, @floatFromInt(ai.base.width)),
            .height = @as(f32, @floatFromInt(ai.base.height)),
        })) {
            ball.speed_x *= -1;
        }

        ball.update();
        player.update();
        ai.update(&ball);
        scorer.update(&ball);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        rl.drawLine(screenWidth / 2, 0, screenWidth / 2, screenHeight, rl.Color.white);

        ball.draw();
        player.draw();
        ai.draw();
        scorer.draw();
    }
}
