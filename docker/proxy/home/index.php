<?php
// lists the odoo instances currently attached to the proxy network, so the
// user can pick one; discovery is done through the docker api because
// instances come and go with the worktrees
const SOCKET = '/var/run/docker.sock';
const NETWORK = 'odoo-proxy-network';

function docker_get(string $path): array
{
    $sock = stream_socket_client('unix://' . SOCKET, $errno, $errstr, 5);
    if (!$sock) {
        return [];
    }
    fwrite($sock, "GET $path HTTP/1.0\r\nHost: localhost\r\n\r\n");
    $raw = stream_get_contents($sock);
    fclose($sock);

    $body = substr($raw, strpos($raw, "\r\n\r\n") + 4);
    return json_decode($body, true) ?: [];
}

/** @return string[] subdomains of the running odoo containers */
function instances(): array
{
    $filters = urlencode(json_encode(['network' => [NETWORK]]));
    $names = [];
    foreach (docker_get("/containers/json?filters=$filters") as $container) {
        $labels = $container['Labels'] ?? [];
        if (($labels['com.docker.compose.service'] ?? '') !== 'odoo') {
            continue;
        }
        // the project is "<prefix>_<instance>", and ./o derives the subdomain
        // from that same instance name
        $project = $labels['com.docker.compose.project'] ?? '';
        if (str_contains($project, '_')) {
            $names[] = substr($project, strpos($project, '_') + 1);
        }
    }
    $names = array_unique($names);
    sort($names);
    return $names;
}

$instances = instances();
?>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>odoo instances</title>
	<style>
		body { font-family: sans-serif; margin: 3rem auto; max-width: 40rem; }
		li { margin: .4rem 0; font-size: 1.2rem; }
		code { color: #666; }
	</style>
</head>
<body>
	<h1>Running odoo instances</h1>
	<?php if (!$instances): ?>
		<p>None. Start one with <code>./o</code> from a worktree.</p>
	<?php else: ?>
		<ul>
		<?php foreach ($instances as $name): ?>
			<li><a href="//<?= htmlspecialchars($name) ?>.localhost/"><?= htmlspecialchars($name) ?></a></li>
		<?php endforeach ?>
		</ul>
	<?php endif ?>
</body>
</html>
