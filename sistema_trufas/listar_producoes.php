
<?php
header('Content-Type: application/json; charset=utf-8');

$con = new mysqli("localhost", "root", "", "sistema_trufas");

$sql = "SELECT p.id, u.nome AS produtor,
        p.estoque, p.valor_unitario
        FROM producoes p
        JOIN usuarios u ON p.produtor_id = u.id
        WHERE p.estoque > 0";

$resultado = $con->query($sql);

$producoes = [];

while ($linha = $resultado->fetch_assoc()) {
    $producoes[] = $linha;
}

echo json_encode($producoes);

$con->close();
?>
