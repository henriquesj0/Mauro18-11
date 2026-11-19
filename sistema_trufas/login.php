
<?php
header('Content-Type: application/json');

$con = new mysqli("localhost", "root", "", "sistema_trufas");

$email = $_POST['email'] ?? '';
$senha = $_POST['senha'] ?? '';

$sql = $con->prepare("SELECT * FROM usuarios WHERE email = ?");
$sql->bind_param("s", $email);
$sql->execute();

$usuario = $sql->get_result()->fetch_assoc();

if ($usuario && password_verify($senha, $usuario['senha'])) {
    echo json_encode([
        "sucesso" => true,
        "id" => $usuario['id'],
        "nome" => $usuario['nome'],
        "perfil" => $usuario['perfil']
    ]);
} else {
    echo json_encode([
        "sucesso" => false,
        "mensagem" => "E-mail ou senha incorretos"
    ]);
}

$con->close();
?>
