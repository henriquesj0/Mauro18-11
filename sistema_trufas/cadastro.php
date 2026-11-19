
<?php
header('Content-Type: application/json');

$con = new mysqli("localhost", "root", "", "sistema_trufas");

if ($con->connect_error) {
    die(json_encode(["mensagem" => "Erro na conexão"]));
}

$nome = $_POST['nome'] ?? '';
$email = $_POST['email'] ?? '';
$senha = $_POST['senha'] ?? '';
$perfil = $_POST['perfil'] ?? '';

if ($nome == '' || $email == '' || $senha == '' ||
    !in_array($perfil, ['produtor', 'vendedor'])) {
    echo json_encode(["mensagem" => "Dados inválidos"]);
    exit;
}

$senha = password_hash($senha, PASSWORD_DEFAULT);

$sql = $con->prepare(
    "INSERT INTO usuarios (nome, email, senha, perfil)
     VALUES (?, ?, ?, ?)"
);

$sql->bind_param("ssss", $nome, $email, $senha, $perfil);

if ($sql->execute()) {
    echo json_encode(["mensagem" => "Cadastro realizado"]);
} else {
    echo json_encode(["mensagem" => "Erro ao cadastrar"]);
}

$con->close();
?>
